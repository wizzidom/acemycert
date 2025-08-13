-- Cybersecurity Quiz Platform - Supabase Database Schema
-- This schema supports the Flutter app with real authentication and data storage

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================
-- CERTIFICATIONS & SECTIONS
-- =============================================

-- Certifications table (ISC² CC, CompTIA Security+, etc.)
CREATE TABLE certifications (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    icon_url TEXT,
    total_questions INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Sections/Domains within certifications
CREATE TABLE sections (
    id TEXT PRIMARY KEY,
    certification_id TEXT NOT NULL REFERENCES certifications(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    question_count INTEGER DEFAULT 0,
    order_index INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- QUESTIONS & ANSWERS
-- =============================================

-- Questions table (stores all quiz questions)
CREATE TABLE questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    certification_id TEXT NOT NULL REFERENCES certifications(id) ON DELETE CASCADE,
    section_id TEXT REFERENCES sections(id) ON DELETE CASCADE,
    text TEXT NOT NULL,
    explanation TEXT NOT NULL,
    difficulty_level TEXT DEFAULT 'medium' CHECK (difficulty_level IN ('easy', 'medium', 'hard')),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Answers table (multiple choice options for each question)
CREATE TABLE answers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    question_id UUID NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
    text TEXT NOT NULL,
    is_correct BOOLEAN DEFAULT false,
    order_index INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- USER PROFILES & PROGRESS
-- =============================================

-- User profiles (extends Supabase auth.users)
CREATE TABLE user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    current_streak INTEGER DEFAULT 0,
    total_questions_answered INTEGER DEFAULT 0,
    total_quizzes_completed INTEGER DEFAULT 0,
    last_activity_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User progress per certification
CREATE TABLE user_certification_progress (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    certification_id TEXT NOT NULL REFERENCES certifications(id) ON DELETE CASCADE,
    questions_answered INTEGER DEFAULT 0,
    correct_answers INTEGER DEFAULT 0,
    quizzes_completed INTEGER DEFAULT 0,
    average_score DECIMAL(5,2) DEFAULT 0.00,
    best_score DECIMAL(5,2) DEFAULT 0.00,
    last_attempt TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, certification_id)
);

-- =============================================
-- QUIZ HISTORY & RESULTS
-- =============================================

-- Quiz history (completed quizzes)
CREATE TABLE quiz_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    quiz_id TEXT NOT NULL, -- Generated quiz ID from Flutter app
    certification_id TEXT NOT NULL REFERENCES certifications(id),
    certification_name TEXT NOT NULL,
    section_id TEXT REFERENCES sections(id),
    section_name TEXT,
    score_percentage DECIMAL(5,2) NOT NULL,
    correct_answers INTEGER NOT NULL,
    total_questions INTEGER NOT NULL,
    time_taken_seconds INTEGER NOT NULL,
    is_passing BOOLEAN GENERATED ALWAYS AS (score_percentage >= 70) STORED,
    completed_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Quiz question results (detailed results for each question in a quiz)
CREATE TABLE quiz_question_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    quiz_history_id UUID NOT NULL REFERENCES quiz_history(id) ON DELETE CASCADE,
    question_id UUID NOT NULL REFERENCES questions(id),
    selected_answer_id UUID REFERENCES answers(id),
    is_correct BOOLEAN NOT NULL,
    answered_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- INDEXES FOR PERFORMANCE
-- =============================================

-- Questions indexes
CREATE INDEX idx_questions_certification_id ON questions(certification_id);
CREATE INDEX idx_questions_section_id ON questions(section_id);
CREATE INDEX idx_questions_active ON questions(is_active);

-- Answers indexes
CREATE INDEX idx_answers_question_id ON answers(question_id);
CREATE INDEX idx_answers_correct ON answers(is_correct);

-- Quiz history indexes
CREATE INDEX idx_quiz_history_user_id ON quiz_history(user_id);
CREATE INDEX idx_quiz_history_certification_id ON quiz_history(certification_id);
CREATE INDEX idx_quiz_history_completed_at ON quiz_history(completed_at DESC);
CREATE INDEX idx_quiz_history_user_cert ON quiz_history(user_id, certification_id);

-- Quiz question results indexes
CREATE INDEX idx_quiz_question_results_quiz_history_id ON quiz_question_results(quiz_history_id);
CREATE INDEX idx_quiz_question_results_question_id ON quiz_question_results(question_id);

-- User progress indexes
CREATE INDEX idx_user_certification_progress_user_id ON user_certification_progress(user_id);
CREATE INDEX idx_user_certification_progress_cert_id ON user_certification_progress(certification_id);

-- =============================================
-- ROW LEVEL SECURITY (RLS)
-- =============================================

-- Enable RLS on all tables
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_certification_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_question_results ENABLE ROW LEVEL SECURITY;

-- User profiles policies
CREATE POLICY "Users can view own profile" ON user_profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON user_profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- User certification progress policies
CREATE POLICY "Users can view own progress" ON user_certification_progress
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own progress" ON user_certification_progress
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own progress" ON user_certification_progress
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Quiz history policies
CREATE POLICY "Users can view own quiz history" ON quiz_history
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own quiz history" ON quiz_history
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Quiz question results policies
CREATE POLICY "Users can view own quiz results" ON quiz_question_results
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM quiz_history 
            WHERE quiz_history.id = quiz_question_results.quiz_history_id 
            AND quiz_history.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert own quiz results" ON quiz_question_results
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM quiz_history 
            WHERE quiz_history.id = quiz_question_results.quiz_history_id 
            AND quiz_history.user_id = auth.uid()
        )
    );

-- Public read access for certifications, sections, questions, and answers
ALTER TABLE certifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE answers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view active certifications" ON certifications
    FOR SELECT USING (is_active = true);

CREATE POLICY "Anyone can view active sections" ON sections
    FOR SELECT USING (is_active = true);

CREATE POLICY "Anyone can view active questions" ON questions
    FOR SELECT USING (is_active = true);

CREATE POLICY "Anyone can view answers" ON answers
    FOR SELECT USING (true);

-- =============================================
-- FUNCTIONS & TRIGGERS
-- =============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for updated_at
CREATE TRIGGER update_certifications_updated_at BEFORE UPDATE ON certifications
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sections_updated_at BEFORE UPDATE ON sections
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_questions_updated_at BEFORE UPDATE ON questions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON user_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_certification_progress_updated_at BEFORE UPDATE ON user_certification_progress
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to automatically create user profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_profiles (id, name, email)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'name', 'User'),
        NEW.email
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create profile on user signup
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Function to update user statistics after quiz completion
CREATE OR REPLACE FUNCTION update_user_stats_after_quiz()
RETURNS TRIGGER AS $$
BEGIN
    -- Update user profile stats
    UPDATE user_profiles 
    SET 
        total_quizzes_completed = total_quizzes_completed + 1,
        total_questions_answered = total_questions_answered + NEW.total_questions,
        last_activity_date = NEW.completed_at,
        updated_at = NOW()
    WHERE id = NEW.user_id;
    
    -- Update or insert certification progress
    INSERT INTO user_certification_progress (
        user_id, 
        certification_id, 
        questions_answered, 
        correct_answers, 
        quizzes_completed,
        average_score,
        best_score,
        last_attempt
    )
    VALUES (
        NEW.user_id,
        NEW.certification_id,
        NEW.total_questions,
        NEW.correct_answers,
        1,
        NEW.score_percentage,
        NEW.score_percentage,
        NEW.completed_at
    )
    ON CONFLICT (user_id, certification_id) 
    DO UPDATE SET
        questions_answered = user_certification_progress.questions_answered + NEW.total_questions,
        correct_answers = user_certification_progress.correct_answers + NEW.correct_answers,
        quizzes_completed = user_certification_progress.quizzes_completed + 1,
        average_score = (
            (user_certification_progress.average_score * user_certification_progress.quizzes_completed + NEW.score_percentage) 
            / (user_certification_progress.quizzes_completed + 1)
        ),
        best_score = GREATEST(user_certification_progress.best_score, NEW.score_percentage),
        last_attempt = NEW.completed_at,
        updated_at = NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update stats after quiz completion
CREATE TRIGGER update_stats_after_quiz_completion
    AFTER INSERT ON quiz_history
    FOR EACH ROW EXECUTE FUNCTION update_user_stats_after_quiz();