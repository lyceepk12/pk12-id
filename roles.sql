-- À exécuter dans Supabase > SQL Editor (après supabase.sql)
-- 1. Table des rôles
create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'scanner' check (role in ('admin','scanner'))
);
alter table public.profiles enable row level security;
drop policy if exists "lire son role" on public.profiles;
create policy "lire son role" on public.profiles
  for select to authenticated using (user_id = auth.uid());

-- 2. Fonction de test du rôle admin
create or replace function public.is_admin() returns boolean
language sql security definer set search_path = public stable as $$
  select exists (select 1 from public.profiles where user_id = auth.uid() and role = 'admin')
$$;

-- 3. Tout nouveau compte = scanner par défaut
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (user_id) values (new.id) on conflict do nothing;
  return new;
end $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- Comptes déjà existants = scanner
insert into public.profiles (user_id) select id from auth.users on conflict do nothing;

-- 4. VOTRE compte = admin (remplacez l'email !)
update public.profiles set role = 'admin'
  where user_id = (select id from auth.users where email = 'lycee-pk12@hotmail.com');

-- 5. Droits sur les élèves : tous lisent, seul l'admin modifie
drop policy if exists "enseignants: accès complet" on public.students;
drop policy if exists "lecture" on public.students;
drop policy if exists "ecriture admin" on public.students;
drop policy if exists "maj admin" on public.students;
drop policy if exists "suppression admin" on public.students;
create policy "lecture" on public.students for select to authenticated using (true);
create policy "ecriture admin" on public.students for insert to authenticated with check (public.is_admin());
create policy "maj admin" on public.students for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "suppression admin" on public.students for delete to authenticated using (public.is_admin());

-- 6. Droits sur les photos
drop policy if exists "enseignants: photos" on storage.objects;
drop policy if exists "photos lecture" on storage.objects;
drop policy if exists "photos ecriture admin" on storage.objects;
drop policy if exists "photos maj admin" on storage.objects;
drop policy if exists "photos suppression admin" on storage.objects;
create policy "photos lecture" on storage.objects for select to authenticated using (bucket_id = 'photos');
create policy "photos ecriture admin" on storage.objects for insert to authenticated with check (bucket_id = 'photos' and public.is_admin());
create policy "photos maj admin" on storage.objects for update to authenticated using (bucket_id = 'photos' and public.is_admin());
create policy "photos suppression admin" on storage.objects for delete to authenticated using (bucket_id = 'photos' and public.is_admin());
