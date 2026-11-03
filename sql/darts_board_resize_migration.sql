-- ダーツ練習記録：ボードの寸法を、自宅のソフトダーツボードの実測値に合わせる（2026-11-04）
-- これまでの記録は、スティールダーツの寸法（アウターブル半径15.9mm、トリプル99〜107mm、ダブル162〜170mm）の
-- ボードの絵の上でタップしていたので、座標（mm）をリングごとに実物の寸法へ換算する。
-- リングの判定（ring）と点数は変わらない（リングの境目どうしを対応させて伸ばすため）。
--
-- 実測（各リングの幅、ふちは除く）：インナーブル直径18mm、アウターブル直径43mm、
-- 内側シングル82mm、トリプル16mm、外側シングル50mm、ダブル16mm
-- → 中心からの半径：インナーブル 9、アウターブル 21.5、トリプル 103.5〜119.5、ダブル 169.5〜185.5
--
-- Supabase の SQL Editor で1回だけ実行してください（2回目はエラーで止まります）。
-- 換算するのは、この寸法に変える前に保存したゲーム（game_id 55 まで）だけです。
-- 元の座標は public.darts_throws_backup_20261104 に残します。

begin;

create table if not exists public.darts_migrations (
  name text primary key,
  applied_at timestamptz not null default now()
);
alter table public.darts_migrations enable row level security;
revoke all on table public.darts_migrations from anon, authenticated;

do $$
begin
  if exists (select 1 from public.darts_migrations where name = 'board-resize-2026-11-04') then
    raise exception 'この換算はすでに実行済みです（2回実行すると座標がさらに伸びてしまうため止めました）';
  end if;
end $$;

-- 元の座標の控え（公開キーからは読めないようにする）
create table public.darts_throws_backup_20261104 as
  select * from public.darts_throws;
alter table public.darts_throws_backup_20261104 enable row level security;
revoke all on table public.darts_throws_backup_20261104 from anon, authenticated;

-- 中心からの距離 r（旧）を、リングごとの直線で新しい距離へ写し、向きはそのままにする
with old as (
  select id, sqrt(x * x + y * y) as r
  from public.darts_throws
  where game_id <= 55 and x is not null and y is not null
), factor as (
  select id,
    case
      when r = 0 then 1
      when r <= 6.35 then (r * 9 / 6.35) / r
      when r <= 15.9 then (9 + (r - 6.35) * (21.5 - 9) / (15.9 - 6.35)) / r
      when r <= 99 then (21.5 + (r - 15.9) * (103.5 - 21.5) / (99 - 15.9)) / r
      when r <= 107 then (103.5 + (r - 99) * (119.5 - 103.5) / (107 - 99)) / r
      when r <= 162 then (119.5 + (r - 107) * (169.5 - 119.5) / (162 - 107)) / r
      when r <= 170 then (169.5 + (r - 162) * (185.5 - 169.5) / (170 - 162)) / r
      else (185.5 + (r - 170)) / r
    end as k
  from old
)
update public.darts_throws t
set x = round((t.x * f.k)::numeric, 1),
    y = round((t.y * f.k)::numeric, 1)
from factor f
where t.id = f.id;

insert into public.darts_migrations (name) values ('board-resize-2026-11-04');

commit;
