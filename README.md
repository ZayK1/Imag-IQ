# Imag-IQ — AI-Powered Quiz Builder

A Flutter web app where teachers create quizzes and students take them with AI-powered learning feedback.

## Quick Start

```bash
# 1) Create a .env file in the project root
OPENROUTER_API_KEY=your_key_here
OPENROUTER_MODEL=openai/gpt-4o-mini

# 2) Install packages
flutter pub get

# 3) Launch
flutter run -d chrome
```

Get a free API key at [openrouter.ai](https://openrouter.ai) (takes ~30 seconds). The AI features (question generation + practice questions) require a valid key. The rest of the app works without one.

## What It Does

**Teacher side:**
- Create and manage multiple quizzes
- Set a topic and focus area (General / Theory / Practical / Problem-Solving)
- Add questions manually or generate them with AI
- AI generates 3 MCQ questions per request, complete with wrong-answer explanations baked in
- Review, accept, edit, or discard AI suggestions before they enter the quiz

**Student side:**
- Browse and take available quizzes
- See score and per-question breakdown after submitting
- For each wrong answer: instant feedback explaining why their choice was incorrect (no loading — explanations were generated at quiz creation time)
- "Practice this" button generates a follow-up question on the same topic using the same AI system

## The AI Design

**One system, two applications.** There's a single AI generation function (`AiService.generateQuestions`) that takes a topic and focus area and returns structured questions with wrong-answer explanations embedded in every option. This same function is called:

1. When a teacher clicks "Generate Questions" — creates quiz content
2. When a student clicks "Practice this" — creates follow-up practice

The wrong-answer explanations explain the misconception behind each wrong choice without simply revealing the correct answer. These explanations are generated alongside the questions themselves, so when a student sees their results, the feedback is **instant** — no API call needed.

**Why this matters:** Most quiz apps treat AI as a grading add-on. Imag-IQ treats it as a content generation system that creates the entire learning loop — questions, distractors, and targeted feedback — in one step.

## Architecture

```
lib/
  main.dart              — App entry, Provider setup
  theme.dart             — Pastel neo-brutal design system
  models/quiz.dart       — Quiz, QuizQuestion, OptionChoice, FocusArea, QuizAttempt
  store/quiz_store.dart  — In-memory state management (ChangeNotifier)
  services/ai_service.dart — OpenRouter API integration (single generation method)
  screens/
    shell.dart           — App shell with Teacher/Student toggle
    teacher/             — Quiz list + builder with AI generation
    student/             — Quiz picker, take quiz, results + practice
  widgets/               — NeoBox, NeoButton (reusable neo-brutal components)
```

**Decisions:**
- **Provider + ChangeNotifier** — simplest state management that works. No over-engineering for a prototype.
- **In-memory state** — no backend, no database. One seeded "Python Basics" quiz so the app is demo-ready immediately.
- **IndexedStack** for role switching — teacher drafts persist when switching to student view and back.
- **Project-level `.env`** — simplest way to run the prototype with OpenRouter locally.
- **OpenRouter** with `openai/gpt-4o-mini` — shared across teacher drafting and student follow-up practice.

## What I'd Build With More Time

- **Persistent storage** — Hive or Supabase so quizzes survive page refresh
- **Teacher analytics** — which questions students get wrong most, which explanations they see repeatedly
- **Adaptive difficulty** — AI adjusts follow-up question difficulty based on how many a student gets wrong
- **Richer question types** — code snippets with syntax highlighting, fill-in-the-blank, drag-to-order
- **Retry flow** — students retake quizzes and track score improvement over time
- **Classroom mode** — teacher shares a quiz code, students join and take it live
- **Smarter practice** — track which skill tags a student struggles with across quizzes, generate targeted practice sets
- **Question editing** — allow teachers to edit questions after adding them (currently only add/delete)
- **Export** — export quiz as PDF or share link

## Tech Stack

- Flutter 3.41 (Web)
- Provider for state management
- OpenRouter API (OpenAI GPT-4o Mini)
- Google Fonts (Space Grotesk)
