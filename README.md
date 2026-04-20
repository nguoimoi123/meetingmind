# MeetingMind

MeetingMind is a smart meeting assistant platform built as a multi-part system with a Flutter client app, a Flask backend, and a separate React/Vite admin dashboard.

## Overview

This repository contains the full MeetingMind ecosystem:

- `meetingmind_ai`: the main Flutter application
- `meetingmind_ai_backend`: the Flask backend and realtime services
- `meetingmind_admin_web`: a separate admin dashboard built with React + Vite

The platform is designed to support meeting capture, realtime transcription, AI summaries, reminders, notebook-based knowledge management, and team collaboration.

## Core Features

- Google / email-based authentication
- Realtime meeting transcription
- AI-generated summaries and action items
- Notebook and meeting knowledge management
- Reminder and scheduling features
- Team collaboration flows
- Global search across meeting content
- Admin dashboard for internal management

## Tech Stack

### Mobile App
- Flutter
- Dart
- Provider
- Go Router
- Dio
- Hive
- Shared Preferences
- Speech-to-Text
- Socket.IO Client
- Google Sign-In
- Google Generative AI
- LiveKit Client

### Backend
- Flask
- Flask-SocketIO
- MongoDB / MongoEngine
- OpenAI
- Speechmatics
- Python

### Admin Dashboard
- React
- Vite

## Repository Structure

```text
meetingmind/
  meetingmind_ai/           # Flutter app
  meetingmind_ai_backend/   # Flask backend
  meetingmind_admin_web/    # Admin dashboard
