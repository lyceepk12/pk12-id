-- À exécuter dans Supabase > SQL Editor (une seule fois)
-- Ajoute le type de personne : élève, enseignant ou personnel administratif.
-- La colonne class_name sert de "groupe" : classe (élève), discipline (enseignant) ou fonction (personnel).
alter table public.students
  add column if not exists kind text not null default 'eleve'
  check (kind in ('eleve','enseignant','personnel'));
create index if not exists students_kind_idx on public.students (kind, class_name);
