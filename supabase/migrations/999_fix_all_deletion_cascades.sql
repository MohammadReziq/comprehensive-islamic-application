-- ═══════════════════════════════════════════════════════════════════════════════
-- Migration: Enable Global User Deletion (SUPER ROBUST VERSION)
-- نفذ هذا الكود في Supabase SQL Editor.
-- هذا النسخة تبحث ديناميكياً عن أسماء "القيود" (Constraints) وتحذفها قبل التجديد.
-- ═══════════════════════════════════════════════════════════════════════════════

DO $$
DECLARE
    r RECORD;
BEGIN
    -- 1. public.users (auth_id) -> auth.users
    FOR r IN (SELECT constraint_name FROM information_schema.key_column_usage WHERE table_name = 'users' AND column_name = 'auth_id' AND table_schema = 'public') LOOP
        EXECUTE 'ALTER TABLE public.users DROP CONSTRAINT ' || quote_ident(r.constraint_name);
    END LOOP;
    ALTER TABLE public.users ADD CONSTRAINT users_auth_id_fkey FOREIGN KEY (auth_id) REFERENCES auth.users(id) ON DELETE CASCADE;

    -- 2. children (parent_id) -> users
    FOR r IN (SELECT constraint_name FROM information_schema.key_column_usage WHERE table_name = 'children' AND column_name = 'parent_id' AND table_schema = 'public') LOOP
        EXECUTE 'ALTER TABLE public.children DROP CONSTRAINT ' || quote_ident(r.constraint_name);
    END LOOP;
    ALTER TABLE public.children ADD CONSTRAINT children_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.users(id) ON DELETE CASCADE;

    -- 3. children (login_user_id) -> users
    FOR r IN (SELECT constraint_name FROM information_schema.key_column_usage WHERE table_name = 'children' AND column_name = 'login_user_id' AND table_schema = 'public') LOOP
        EXECUTE 'ALTER TABLE public.children DROP CONSTRAINT ' || quote_ident(r.constraint_name);
    END LOOP;
    ALTER TABLE public.children ADD CONSTRAINT children_login_user_id_fkey FOREIGN KEY (login_user_id) REFERENCES public.users(id) ON DELETE SET NULL;

    -- 4. mosques (owner_id) -> users
    FOR r IN (SELECT constraint_name FROM information_schema.key_column_usage WHERE table_name = 'mosques' AND column_name = 'owner_id' AND table_schema = 'public') LOOP
        EXECUTE 'ALTER TABLE public.mosques DROP CONSTRAINT ' || quote_ident(r.constraint_name);
    END LOOP;
    ALTER TABLE public.mosques ADD CONSTRAINT mosques_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.users(id) ON DELETE CASCADE;

    -- 5. attendance (recorded_by_id) -> users
    FOR r IN (SELECT constraint_name FROM information_schema.key_column_usage WHERE table_name = 'attendance' AND column_name = 'recorded_by_id' AND table_schema = 'public') LOOP
        EXECUTE 'ALTER TABLE public.attendance DROP CONSTRAINT ' || quote_ident(r.constraint_name);
    END LOOP;
    ALTER TABLE public.attendance ADD CONSTRAINT attendance_recorded_by_id_fkey FOREIGN KEY (recorded_by_id) REFERENCES public.users(id) ON DELETE CASCADE;

    -- 6. attendance (mosque_id) -> mosques
    FOR r IN (SELECT constraint_name FROM information_schema.key_column_usage WHERE table_name = 'attendance' AND column_name = 'mosque_id' AND table_schema = 'public') LOOP
        EXECUTE 'ALTER TABLE public.attendance DROP CONSTRAINT ' || quote_ident(r.constraint_name);
    END LOOP;
    ALTER TABLE public.attendance ADD CONSTRAINT attendance_mosque_id_fkey FOREIGN KEY (mosque_id) REFERENCES public.mosques(id) ON DELETE SET NULL;

    -- 7. attendance (competition_id) -> competitions
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'attendance' AND column_name = 'competition_id') THEN
        FOR r IN (SELECT constraint_name FROM information_schema.key_column_usage WHERE table_name = 'attendance' AND column_name = 'competition_id' AND table_schema = 'public') LOOP
            EXECUTE 'ALTER TABLE public.attendance DROP CONSTRAINT ' || quote_ident(r.constraint_name);
        END LOOP;
        ALTER TABLE public.attendance ADD CONSTRAINT attendance_competition_id_fkey FOREIGN KEY (competition_id) REFERENCES public.competitions(id) ON DELETE SET NULL;
    END IF;

    -- 8. rewards (parent_id) -> users
    FOR r IN (SELECT constraint_name FROM information_schema.key_column_usage WHERE table_name = 'rewards' AND column_name = 'parent_id' AND table_schema = 'public') LOOP
        EXECUTE 'ALTER TABLE public.rewards DROP CONSTRAINT ' || quote_ident(r.constraint_name);
    END LOOP;
    ALTER TABLE public.rewards ADD CONSTRAINT rewards_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.users(id) ON DELETE CASCADE;

    -- 9. correction_requests (parent_id) -> users
    FOR r IN (SELECT constraint_name FROM information_schema.key_column_usage WHERE table_name = 'correction_requests' AND column_name = 'parent_id' AND table_schema = 'public') LOOP
        EXECUTE 'ALTER TABLE public.correction_requests DROP CONSTRAINT ' || quote_ident(r.constraint_name);
    END LOOP;
    ALTER TABLE public.correction_requests ADD CONSTRAINT correction_requests_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.users(id) ON DELETE CASCADE;

    -- 10. correction_requests (reviewed_by) -> users
    FOR r IN (SELECT constraint_name FROM information_schema.key_column_usage WHERE table_name = 'correction_requests' AND column_name = 'reviewed_by' AND table_schema = 'public') LOOP
        EXECUTE 'ALTER TABLE public.correction_requests DROP CONSTRAINT ' || quote_ident(r.constraint_name);
    END LOOP;
    ALTER TABLE public.correction_requests ADD CONSTRAINT correction_requests_reviewed_by_fkey FOREIGN KEY (reviewed_by) REFERENCES public.users(id) ON DELETE SET NULL;

    -- 11. correction_requests (mosque_id) -> mosques
    FOR r IN (SELECT constraint_name FROM information_schema.key_column_usage WHERE table_name = 'correction_requests' AND column_name = 'mosque_id' AND table_schema = 'public') LOOP
        EXECUTE 'ALTER TABLE public.correction_requests DROP CONSTRAINT ' || quote_ident(r.constraint_name);
    END LOOP;
    ALTER TABLE public.correction_requests ADD CONSTRAINT correction_requests_mosque_id_fkey FOREIGN KEY (mosque_id) REFERENCES public.mosques(id) ON DELETE CASCADE;

    -- 12. notes (sender_id) -> users
    FOR r IN (SELECT constraint_name FROM information_schema.key_column_usage WHERE table_name = 'notes' AND column_name = 'sender_id' AND table_schema = 'public') LOOP
        EXECUTE 'ALTER TABLE public.notes DROP CONSTRAINT ' || quote_ident(r.constraint_name);
    END LOOP;
    ALTER TABLE public.notes ADD CONSTRAINT notes_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.users(id) ON DELETE CASCADE;

    -- 13. notes (mosque_id) -> mosques
    FOR r IN (SELECT constraint_name FROM information_schema.key_column_usage WHERE table_name = 'notes' AND column_name = 'mosque_id' AND table_schema = 'public') LOOP
        EXECUTE 'ALTER TABLE public.notes DROP CONSTRAINT ' || quote_ident(r.constraint_name);
    END LOOP;
    ALTER TABLE public.notes ADD CONSTRAINT notes_mosque_id_fkey FOREIGN KEY (mosque_id) REFERENCES public.mosques(id) ON DELETE CASCADE;

    -- 14. announcements (sender_id) -> users
    FOR r IN (SELECT constraint_name FROM information_schema.key_column_usage WHERE table_name = 'announcements' AND column_name = 'sender_id' AND table_schema = 'public') LOOP
        EXECUTE 'ALTER TABLE public.announcements DROP CONSTRAINT ' || quote_ident(r.constraint_name);
    END LOOP;
    ALTER TABLE public.announcements ADD CONSTRAINT announcements_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.users(id) ON DELETE CASCADE;

    -- 15. competitions (created_by) -> users
    FOR r IN (SELECT constraint_name FROM information_schema.key_column_usage WHERE table_name = 'competitions' AND column_name = 'created_by' AND table_schema = 'public') LOOP
        EXECUTE 'ALTER TABLE public.competitions DROP CONSTRAINT ' || quote_ident(r.constraint_name);
    END LOOP;
    ALTER TABLE public.competitions ADD CONSTRAINT competitions_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE CASCADE;

    -- 16. supervisor_credentials -> auth.users
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'supervisor_credentials' AND table_schema = 'public') THEN
        FOR r IN (SELECT constraint_name FROM information_schema.key_column_usage WHERE table_name = 'supervisor_credentials' AND column_name = 'user_id' AND table_schema = 'public') LOOP
            EXECUTE 'ALTER TABLE public.supervisor_credentials DROP CONSTRAINT ' || quote_ident(r.constraint_name);
        END LOOP;
        ALTER TABLE public.supervisor_credentials ADD CONSTRAINT supervisor_credentials_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;

    -- 17. announcement_reads -> users
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'announcement_reads' AND table_schema = 'public') THEN
        FOR r IN (SELECT constraint_name FROM information_schema.key_column_usage WHERE table_name = 'announcement_reads' AND column_name = 'user_id' AND table_schema = 'public') LOOP
            EXECUTE 'ALTER TABLE public.announcement_reads DROP CONSTRAINT ' || quote_ident(r.constraint_name);
        END LOOP;
        ALTER TABLE public.announcement_reads ADD CONSTRAINT announcement_reads_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
    END IF;

    -- 18. mosque_members -> users
    FOR r IN (SELECT constraint_name FROM information_schema.key_column_usage WHERE table_name = 'mosque_members' AND column_name = 'user_id' AND table_schema = 'public') LOOP
        EXECUTE 'ALTER TABLE public.mosque_members DROP CONSTRAINT ' || quote_ident(r.constraint_name);
    END LOOP;
    ALTER TABLE public.mosque_members ADD CONSTRAINT mosque_members_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

    -- 19. mosque_join_requests -> users (user_id)
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'mosque_join_requests' AND table_schema = 'public') THEN
        FOR r IN (SELECT constraint_name FROM information_schema.key_column_usage WHERE table_name = 'mosque_join_requests' AND column_name = 'user_id' AND table_schema = 'public') LOOP
            EXECUTE 'ALTER TABLE public.mosque_join_requests DROP CONSTRAINT ' || quote_ident(r.constraint_name);
        END LOOP;
        ALTER TABLE public.mosque_join_requests ADD CONSTRAINT mosque_join_requests_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
        
        FOR r IN (SELECT constraint_name FROM information_schema.key_column_usage WHERE table_name = 'mosque_join_requests' AND column_name = 'reviewed_by' AND table_schema = 'public') LOOP
            EXECUTE 'ALTER TABLE public.mosque_join_requests DROP CONSTRAINT ' || quote_ident(r.constraint_name);
        END LOOP;
        ALTER TABLE public.mosque_join_requests ADD CONSTRAINT mosque_join_requests_reviewed_by_fkey FOREIGN KEY (reviewed_by) REFERENCES public.users(id) ON DELETE SET NULL;
    END IF;

    -- 20. mosque_code_attempts -> users
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'mosque_code_attempts' AND table_schema = 'public') THEN
        FOR r IN (SELECT constraint_name FROM information_schema.key_column_usage WHERE table_name = 'mosque_code_attempts' AND column_name = 'user_id' AND table_schema = 'public') LOOP
            EXECUTE 'ALTER TABLE public.mosque_code_attempts DROP CONSTRAINT ' || quote_ident(r.constraint_name);
        END LOOP;
        ALTER TABLE public.mosque_code_attempts ADD CONSTRAINT mosque_code_attempts_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
    END IF;

END $$;




