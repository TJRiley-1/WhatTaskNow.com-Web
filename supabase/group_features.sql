-- Group Management Features - Run in Supabase SQL Editor

-- 1. UPDATE policy for groups (allows creators to edit group name/description)
CREATE POLICY "Group creators can update their groups" ON groups
  FOR UPDATE TO authenticated USING (auth.uid() = created_by);

-- 2. Group challenges table
CREATE TABLE group_challenges (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  group_id uuid REFERENCES groups(id) ON DELETE CASCADE NOT NULL,
  title text NOT NULL,
  target_tasks int NOT NULL DEFAULT 50,
  bonus_points int NOT NULL DEFAULT 100,
  start_date timestamptz DEFAULT now() NOT NULL,
  end_date timestamptz DEFAULT (now() + interval '7 days') NOT NULL,
  created_by uuid REFERENCES auth.users(id) NOT NULL,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE group_challenges ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can view group challenges" ON group_challenges
  FOR SELECT TO authenticated USING (is_group_member(group_id));

CREATE POLICY "Creators can manage challenges" ON group_challenges
  FOR INSERT TO authenticated WITH CHECK (
    is_group_member(group_id) AND created_by = auth.uid()
  );

CREATE POLICY "Creators can delete challenges" ON group_challenges
  FOR DELETE TO authenticated USING (created_by = auth.uid());

-- 3. DELETE policy for group_members (allows group creators to remove members)
CREATE POLICY "Group creators can remove members" ON group_members
  FOR DELETE TO authenticated USING (
    group_id IN (SELECT id FROM groups WHERE created_by = auth.uid())
  );
