-- ============================================
-- JLPT N5 学习平台 - Supabase 数据库迁移
-- 在 Supabase SQL Editor 中执行此脚本
-- ============================================

-- 1. 用户学习进度表
CREATE TABLE IF NOT EXISTS user_progress (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
  progress_data JSONB NOT NULL DEFAULT '{
    "version": 1,
    "vocabStudied": {},
    "grammarStudied": {},
    "quizHistory": [],
    "streak": {"count": 0, "lastDate": null}
  }'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. 自动更新 updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON user_progress
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 3. 行级安全策略（RLS）
ALTER TABLE user_progress ENABLE ROW LEVEL SECURITY;

-- 用户只能读取自己的进度
CREATE POLICY "读自己的进度" ON user_progress
  FOR SELECT USING (auth.uid() = user_id);

-- 用户只能插入自己的进度
CREATE POLICY "插入自己的进度" ON user_progress
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 用户只能更新自己的进度
CREATE POLICY "更新自己的进度" ON user_progress
  FOR UPDATE USING (auth.uid() = user_id);
