-- ============================================================
-- CREATE HUB ─ 共有データベース セットアップ
-- ------------------------------------------------------------
-- 使い方：
--   1. https://supabase.com でプロジェクトを作成（Region は Tokyo 推奨）
--   2. 左メニュー「SQL Editor」→「New query」
--   3. このファイルの中身をすべて貼り付けて「Run」を押す
--   4. 左メニュー「Authentication」→「Users」→「Add user」で
--      編集者のメールアドレスとパスワードを登録する
--   5. 「Project Settings」→「API」の Project URL と anon public を
--      index.html の APP_CONFIG.remote に貼り付ける
--
-- ★ service_role キーは絶対に index.html に書かないでください。
-- ============================================================


-- ------------------------------------------------------------
-- ① 編集用テーブル（非公開を含む全データ）
--    ログインした編集者だけが読み書きできる
-- ------------------------------------------------------------
create table if not exists site_data (
  id         int primary key default 1,
  payload    jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now(),
  updated_by text default '',
  constraint site_data_single_row check (id = 1)
);

insert into site_data (id, payload) values (1, '[]'::jsonb)
on conflict (id) do nothing;


-- ------------------------------------------------------------
-- ② 公開用テーブル（公開ONのものだけ）
--    ログインなしで誰でも読める。書き込みは③のトリガーのみ。
-- ------------------------------------------------------------
create table if not exists site_public (
  id         int primary key default 1,
  payload    jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now(),
  constraint site_public_single_row check (id = 1)
);

insert into site_public (id, payload) values (1, '[]'::jsonb)
on conflict (id) do nothing;


-- ------------------------------------------------------------
-- ③ 自動同期トリガー
--    「公開データを更新」が押されたとき、published = true の
--    成果物だけを公開用テーブルへ複製する。
--    → 非公開データはサーバー側で除外され、閲覧者には一切届かない
-- ------------------------------------------------------------
create or replace function sync_site_public() returns trigger as $$
begin
  update site_public
     set payload = coalesce(
           (select jsonb_agg(item)
              from jsonb_array_elements(new.payload) as item
             where (item->>'published')::boolean is true),
           '[]'::jsonb),
         updated_at = now()
   where id = 1;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_sync_site_public on site_data;
create trigger trg_sync_site_public
  after insert or update on site_data
  for each row execute function sync_site_public();


-- ------------------------------------------------------------
-- ④ 更新履歴テーブル（誰がいつ更新したかを自動記録）
-- ------------------------------------------------------------
create table if not exists site_history (
  id          bigserial primary key,
  payload     jsonb not null,
  item_count  int not null default 0,
  changed_by  text default '',
  changed_at  timestamptz not null default now()
);

create or replace function log_site_change() returns trigger as $$
begin
  insert into site_history (payload, item_count, changed_by)
  values (new.payload, jsonb_array_length(new.payload), coalesce(new.updated_by, ''));
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_log_site_change on site_data;
create trigger trg_log_site_change
  after insert or update on site_data
  for each row execute function log_site_change();


-- ============================================================
-- ⑤ アクセス制御（RLS）
--    ★★★ ここが最重要。これが無いと誰でもデータを消せます ★★★
-- ============================================================

-- 編集用テーブル：ログイン者のみ読み書き可
alter table site_data enable row level security;

drop policy if exists "editor_read_site_data"  on site_data;
drop policy if exists "editor_write_site_data" on site_data;

create policy "editor_read_site_data" on site_data
  for select to authenticated using (true);

create policy "editor_write_site_data" on site_data
  for all to authenticated using (true) with check (true);
-- ※ anon（未ログイン）には一切ポリシーを作らない＝読むことも書くこともできない


-- 公開用テーブル：誰でも読めるが、誰も直接は書けない
alter table site_public enable row level security;

drop policy if exists "anyone_read_site_public" on site_public;

create policy "anyone_read_site_public" on site_public
  for select to anon, authenticated using (true);
-- ※ insert / update / delete のポリシーを作らない＝③のトリガー経由でしか更新されない


-- 更新履歴：ログイン者のみ閲覧可（改ざん防止のため書き込みポリシーなし）
alter table site_history enable row level security;

drop policy if exists "editor_read_history" on site_history;

create policy "editor_read_history" on site_history
  for select to authenticated using (true);


-- ============================================================
-- ⑥ 動作確認用クエリ（任意）
-- ============================================================
-- 現在の公開件数を見る
--   select jsonb_array_length(payload) as 公開件数 from site_public where id = 1;
--
-- 更新履歴を新しい順に見る
--   select changed_at, changed_by, item_count from site_history order by id desc limit 20;
--
-- 過去の状態に戻す（履歴IDを指定）
--   update site_data set payload = (select payload from site_history where id = 【戻したいID】) where id = 1;
