-- ============================================================
-- Migration: Classes, Subjects, Class-Subject assignments
-- ============================================================
-- RLS strategy:
--
--   SELECT  → caller must have a valid Clerk JWT sub claim
--             USING ((auth.jwt() ->> 'sub') IS NOT NULL)
--
--   INSERT / UPDATE / DELETE → caller must have a valid JWT sub
--             AND must be an admin/super_admin in admin_profiles
--
-- The is_admin() helper matches the JWT 'sub' claim (Clerk user
-- ID) against admin_profiles.clerk_id.
-- ============================================================


-- ------------------------------------------------------------
-- Helper: is the calling user an admin?
-- ------------------------------------------------------------
-- Uses auth.jwt() ->> 'sub' (the Clerk user ID) to look up the
-- caller in admin_profiles. SECURITY DEFINER lets this function
-- bypass admin_profiles' own RLS.
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
    WHERE clerk_id  = (auth.jwt() ->> 'sub')
      AND role      IN ('admin', 'super_admin')
      AND is_active = true
  );
$$;


-- ------------------------------------------------------------
-- Trigger helper: keep updated_at current
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
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

-- SELECT: any user with a valid Clerk JWT (admin, teacher, student)
CREATE POLICY "classes_select"
  ON public.classes
  FOR SELECT
  USING ((auth.jwt() ->> 'sub') IS NOT NULL);

-- INSERT: valid JWT AND must be an admin
CREATE POLICY "classes_insert"
  ON public.classes
  FOR INSERT
  WITH CHECK (
    (auth.jwt() ->> 'sub') IS NOT NULL
    AND public.is_admin()
  );

-- UPDATE: valid JWT AND must be an admin (on both sides)
CREATE POLICY "classes_update"
  ON public.classes
  FOR UPDATE
  USING (
    (auth.jwt() ->> 'sub') IS NOT NULL
    AND public.is_admin()
  )
  WITH CHECK (
    (auth.jwt() ->> 'sub') IS NOT NULL
    AND public.is_admin()
  );

-- DELETE: valid JWT AND must be an admin
CREATE POLICY "classes_delete"
  ON public.classes
  FOR DELETE
  USING (
    (auth.jwt() ->> 'sub') IS NOT NULL
    AND public.is_admin()
  );

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

-- SELECT: any user with a valid Clerk JWT (admin, teacher, student)
CREATE POLICY "subjects_select"
  ON public.subjects
  FOR SELECT
  USING ((auth.jwt() ->> 'sub') IS NOT NULL);

-- INSERT: valid JWT AND must be an admin
CREATE POLICY "subjects_insert"
  ON public.subjects
  FOR INSERT
  WITH CHECK (
    (auth.jwt() ->> 'sub') IS NOT NULL
    AND public.is_admin()
  );

-- UPDATE: valid JWT AND must be an admin (on both sides)
CREATE POLICY "subjects_update"
  ON public.subjects
  FOR UPDATE
  USING (
    (auth.jwt() ->> 'sub') IS NOT NULL
    AND public.is_admin()
  )
  WITH CHECK (
    (auth.jwt() ->> 'sub') IS NOT NULL
    AND public.is_admin()
  );

-- DELETE: valid JWT AND must be an admin
CREATE POLICY "subjects_delete"
  ON public.subjects
  FOR DELETE
  USING (
    (auth.jwt() ->> 'sub') IS NOT NULL
    AND public.is_admin()
  );

CREATE TRIGGER subjects_set_updated_at
  BEFORE UPDATE ON public.subjects
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


-- ============================================================
-- Table: class_subjects  (junction: class ↔ subject)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.class_subjects (
  id         uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  class_id   uuid        NOT NULL REFERENCES public.classes(id)  ON DELETE RESTRICT,
  subject_id uuid        NOT NULL REFERENCES public.subjects(id) ON DELETE RESTRICT,
  created_at timestamptz NOT NULL DEFAULT now(),

  UNIQUE (class_id, subject_id)
);

ALTER TABLE public.class_subjects ENABLE ROW LEVEL SECURITY;

-- SELECT: any user with a valid Clerk JWT
CREATE POLICY "class_subjects_select"
  ON public.class_subjects
  FOR SELECT
  USING ((auth.jwt() ->> 'sub') IS NOT NULL);

-- INSERT: valid JWT AND must be an admin
CREATE POLICY "class_subjects_insert"
  ON public.class_subjects
  FOR INSERT
  WITH CHECK (
    (auth.jwt() ->> 'sub') IS NOT NULL
    AND public.is_admin()
  );

-- DELETE: valid JWT AND must be an admin
--   (assignments are replaced wholesale: delete + re-insert)
CREATE POLICY "class_subjects_delete"
  ON public.class_subjects
  FOR DELETE
  USING (
    (auth.jwt() ->> 'sub') IS NOT NULL
    AND public.is_admin()
  );
