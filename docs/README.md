# Docs

## Database design (current)
Read these in order. Each describes what's live, with its migrations and access test.

| Doc | Covers |
|---|---|
| [organization-schema.md](organization-schema.md) | Schools (organizations), memberships and roles, claim codes, Hamrash platform admins, suspension |
| [people-schema.md](people-schema.md) | Staff, students, parents and their links. Public profiles vs private details, admission and staff numbers, issuing logins. |
| [academic-structure.md](academic-structure.md) | Sections, classes, arms, sessions and terms, class teachers, student placements. Promotion decisions. |
| [subjects.md](subjects.md) | Subjects, each arm's curriculum, teaching assignments, electives, what teachers can see, preparing a new session |
| [results-design.md](results-design.md) | Grading setup (live) and the plan for the gradebook, publishing and homework |

## How-to
| Doc | Covers |
|---|---|
| [rls-guide.md](rls-guide.md) | **How we write tables, access rules, permissions and functions.** Start here before writing a migration. |
| [../supabase/README.md](../supabase/README.md) | Every migration, how to apply them, the access tests, and the `media-upload` edge function (all image uploads go through it, with no Cloudflare token in the app) |
| [Clerk_Setup_Guide.md](Clerk_Setup_Guide.md) | Setting up Clerk sign-in with Supabase |
| [Supabase_Realm_Architecture_Guide.md](Supabase_Realm_Architecture_Guide.md) | General pattern: Supabase as the source of truth, Realm as the offline cache |
| [project-folder-structure-replication-guide.md](project-folder-structure-replication-guide.md) | The `lib/` folder layout |

## Open work
[../TODO.md](../TODO.md) is the single list of anything still to build or decide.
