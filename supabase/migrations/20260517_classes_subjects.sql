-- ============================================================
-- Migration: Classes, Subjects, Class-Subject assignments
-- ============================================================
-- RLS summary:
--   SELECT  → any authenticated user (admin, teacher, student)
--   INSERT / UPDATE / DELETE → admin or super_admin only
--
-- "Admin" is resolved by looking up the caller's Clerk sub
-- (auth.uid()::text) in public.admin_profiles.role.
-- ============================================================


-- ------------------------------------------------------------
-- Helper: is the calling user an admin?
-- ------------------------------------------------------------
-- Reusable security-definer function so the check never
-- touches the caller's row-level permissions on admin_profiles.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.admin_profiles
    WHERE clerk_id  = auth.uid()::text
      AND role      IN ('admin', 'super_admin')
      AND is_active = true
  );
$$;


-- ============================================================
-- Table: classes
-- ============================================================
CREATE TABLE IF NOT EXISTS public.classes (
  id         uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  name       text        NOT NULL,
  section    text,
  is_active  boolean     NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.classes ENABLE ROW LEVEL SECURITY;

-- Any authenticated user can view classes
CREATE POLICY "classes_select_authenticated"
  ON public.classes
  FOR SELECT
  TO authenticated
  USING (true);

-- Only admins can create classes
CREATE POLICY "classes_insert_admin"
  ON public.classes
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_admin());

-- Only admins can update classes
CREATE POLICY "classes_update_admin"
  ON public.classes
  FOR UPDATE
  TO authenticated
  USING  (public.is_admin())
  WITH CHECK (public.is_admin());

-- Only admins can delete classes
CREATE POLICY "classes_delete_admin"
  ON public.classes
  FOR DELETE
  TO authenticated
  USING (public.is_admin());

-- Auto-update updated_at on row change
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER classes_set_updated_at
  BEFORE UPDATE ON public.classes
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


-- ============================================================
-- Table: subjects
-- ============================================================
CREATE TABLE IF NOT EXISTS public.subjects (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  name        text        NOT NULL,
  description text,
  is_active   boolean     NOT NULL DEFAULT true,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.subjects ENABLE ROW LEVEL SECURITY;

-- Any authenticated user can view subjects
CREATE POLICY "subjects_select_authenticated"
  ON public.subjects
  FOR SELECT
  TO authenticated
  USING (true);

-- Only admins can create subjects
CREATE POLICY "subjects_insert_admin"
  ON public.subjects
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_admin());

-- Only admins can update subjects
CREATE POLICY "subjects_update_admin"
  ON public.subjects
  FOR UPDATE
  TO authenticated
  USING  (public.is_admin())
  WITH CHECK (public.is_admin());

-- Only admins can delete subjects
CREATE POLICY "subjects_delete_admin"
  ON public.subjects
  FOR DELETE
  TO authenticated
  USING (public.is_admin());

CREATE TRIGGER subjects_set_updated_at
  BEFORE UPDATE ON public.subjects
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


-- ============================================================
-- Table: class_subjects  (junction: class ↔ subject)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.class_subjects (
  id         uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  class_id   uuid        NOT NULL REFERENCES public.classes(id)  ON DELETE CASCADE,
  subject_id uuid        NOT NULL REFERENCES public.subjects(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),

  UNIQUE (class_id, subject_id)
);

ALTER TABLE public.class_subjects ENABLE ROW LEVEL SECURITY;

-- Any authenticated user can view class-subject links
CREATE POLICY "class_subjects_select_authenticated"
  ON public.class_subjects
  FOR SELECT
  TO authenticated
  USING (true);

-- Only admins can assign subjects to classes
CREATE POLICY "class_subjects_insert_admin"
  ON public.class_subjects
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_admin());

-- Only admins can remove subject assignments
CREATE POLICY "class_subjects_delete_admin"
  ON public.class_subjects
  FOR DELETE
  TO authenticated
  USING (public.is_admin());
