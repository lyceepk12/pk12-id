-- À exécuter dans Supabase > SQL Editor
create table if not exists public.students (
  id uuid primary key default gen_random_uuid(),
  full_name text not null,
  class_name text not null,
  photo_path text not null,
  descriptor float8[] not null,
  created_at timestamptz default now()
);
create index on public.students (class_name);

alter table public.students enable row level security;
create policy "enseignants: accès complet" on public.students
  for all to authenticated using (true) with check (true);

-- Bucket privé pour les photos
insert into storage.buckets (id, name, public) values ('photos','photos',false)
  on conflict (id) do nothing;
create policy "enseignants: photos" on storage.objects
  for all to authenticated
  using (bucket_id = 'photos') with check (bucket_id = 'photos');
