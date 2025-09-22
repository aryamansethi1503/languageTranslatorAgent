Language Translation Agent - Project Summary & Deployment Guide

 Project Summary
This document summarizes the development of the "Language Translation Agent," a web application built with Streamlit and powered by Google's generative AI models (Gemini and custom models on Vertex AI). The project evolved from a simple translation tool into a robust, production-ready application with a persistent "memory."

Key Features:
Dual Model Support: Translate using both the public Gemini API and custom-deployed models (like Gemma) on Vertex AI.

Text & Document Translation: Supports direct text input and translation of .pdf, .docx, and .txt files.

Dynamic UI: The interface is clean, responsive, and provides advanced options for prompt customization.

AI "Memory" (Human-in-the-Loop):

This is the core advanced feature. The app does not blindly save every translation.

It allows the user to "Edit Translation" if they find a mistake.

Clicking "Save Correction" saves the (source_text, corrected_translation) pair to a persistent Cloud SQL (PostgreSQL) database.

Before any new translation, the app retrieves the 3 most recent corrections from the database and injects them into the prompt as examples. This teaches the AI to learn from past mistakes and adapt to the user's preferred style (a form of in-context learning).

Production Ready: The app is designed for deployment on Google Cloud Run, using a Cloud SQL database for scalable, persistent storage.

Evolution of the Project:
Initial Concept: A simple Streamlit app to translate text and documents.

UI/UX Enhancements: We added custom CSS (Google Sans font, styled text areas) and dynamic UI elements (e.g., editable prompt box).

Core Feature: "AI Memory":

Idea: You suggested the app should "learn from its mistakes."

v1 (Local): We first implemented this using a local sqlite3 database file. This worked perfectly for local development.

v2 (Production): We identified that sqlite3 would fail on Cloud Run due to its "ephemeral" (temporary) filesystem. We re-architected the database logic to use psycopg2, a driver for a production-grade PostgreSQL database (Cloud SQL).

Efficiency (Connection Pooling): Instead of connecting/disconnecting for every database query, we implemented a psycopg2.pool.SimpleConnectionPool and cached it using st.cache_resource. This is the standard, efficient way to manage database connections in a web app.

Deployment Packaging: We created a Dockerfile and requirements.txt file to containerize the app for deployment, including installing necessary fonts (DejaVuSans.ttf) for the PDF generation feature.


Deployment Instructions (Google Cloud Run)
Follow these steps to deploy your application to a scalable, public URL.

Prerequisites:
A Google Cloud Project with billing enabled.

The gcloud command-line tool installed on your local machine.

Step 1: Create the Cloud SQL (PostgreSQL) Database
This is the persistent "memory" for your app.

Go to the Google Cloud Console and navigate to SQL.

Click "Create Instance" and choose "PostgreSQL".

Give it an Instance ID (e.g., translation-db-instance) and set a strong postgres user password. Save this password!

Choose your Region (e.g., us-central1) and select a machine type. For this app, db-f1-micro is a good, low-cost start.

Click "Create Instance". This will take a few minutes.

Once created, go to the Databases tab for your new instance and create a database. The default postgres database is also fine to use.

Step 2: Build and Push Your Docker Image
This packages your app into a container that Cloud Run can execute.

Open a terminal and navigate to the directory containing your 4 files.

Enable the Artifact Registry API in your project.

Create a Docker Repository:

gcloud artifacts repositories create my-docker-repo --repository-format=docker --location=us-central1

Build the Docker Image: (Replace [PROJECT-ID] and [REPO-NAME])

gcloud builds submit --tag us-central1-docker.pkg.dev/[PROJECT-ID]/my-docker-repo/translation-agent:v1

This command automatically builds your Dockerfile in the cloud and pushes the resulting image to your Artifact Registry.

Step 3: Deploy to Cloud Run
This makes your app live on the web.

Go to the Google Cloud Console and navigate to Cloud Run.

Click "Create Service".

Select your image: Choose "Select a container image from Artifact Registry" and find the translation-agent:v1 image you just built.

Give your service a Service name (e.g., translation-agent).

Select a Region (use the same region as your Cloud SQL instance, e.g., us-central1).

Under Authentication, select "Allow unauthenticated invocations" to make it a public website.

CRITICAL: Connect to the Database

Expand the "Container, Variables & Secrets, Connections" section.

Go to the "Connections" tab.

Click "Add Connection" and select the Cloud SQL instance you created in Step 1. This is the "magic" that securely connects Cloud Run to your database.

CRITICAL: Set Environment Variables

Go to the "Variables & Secrets" tab.

Add the following environment variables. The app needs these to log in to the database.

DB_USER: postgres

DB_PASS: The password you set in Step 1.

DB_NAME: postgres (or the name you created).

DB_HOST: This is the most important one. The value must be /cloudsql/[CONNECTION-NAME]. You can find the Connection Name on your Cloud SQL instance's overview page (it looks like my-project:us-central1:translation-db-instance).

Click "Create". Your service will be deployed, and you'll get a public URL to access your fully-functional, persistent translation agent.