# AML Analytics Platform

> An end-to-end **Anti-Money Laundering (AML)** analytics platform built using **FastAPI, MySQL, Power BI, and Railway** that combines behavioral transaction analytics, explainable risk scoring, case management, and interactive dashboards.

![Python](https://img.shields.io/badge/Python-3.11-blue)
![FastAPI](https://img.shields.io/badge/FastAPI-REST_API-009688)
![MySQL](https://img.shields.io/badge/MySQL-Database-orange)
![PowerBI](https://img.shields.io/badge/Power_BI-Dashboards-yellow)
![Railway](https://img.shields.io/badge/Deployed_on-Railway-purple)
![License](https://img.shields.io/badge/License-MIT-green)

---

## 🚀 Live Demo

| Service | URL |
|---------|-----|
| 🌐 API | https://aml-analytics-platform-production.up.railway.app |
| 📖 Swagger Docs | https://aml-analytics-platform-production.up.railway.app/docs |
| 💻 Investigation Workspace | https://aml-analytics-platform-production.up.railway.app/app/login |

> **Note:** Railway may take a few seconds to wake up after inactivity.

---

# Project Overview

Traditional AML systems rely heavily on fixed rules (for example, *transactions above a fixed threshold are suspicious*).

This platform takes a **behavioral analytics approach** by comparing transactions against:

- the account's own historical behavior
- similar peer groups
- explainable risk indicators

instead of relying only on global thresholds.

The platform provides investigators with both:

- a REST API
- a lightweight web-based Investigation Workspace

along with interactive Power BI dashboards.

---

# ✨ Features

## 🔍 Transaction Monitoring

- Search & filter transactions
- Transaction detail view
- Behavioral analysis

---

## Behavioral Analytics

- Rolling account baseline
- Baseline deviation detection
- Peer-group anomaly detection

---

## ⚠️ Explainable Risk Scoring

Risk score combines multiple explainable components:

- Rule-based checks
- Baseline deviation
- Peer anomaly

instead of using a black-box ML model.

---

## 📂 Case Management

- Create investigation cases
- Update case status
- Analyst notes
- Prevent duplicate active cases
- Terminal "Cleared" state enforcement

---

## 🔐 Authentication

- JWT Authentication (API)
- Cookie Authentication (Web Portal)
- Role-based authorization
- Protected write endpoints

---

## 📊 Power BI Dashboards

Three dashboards included:

- Transaction Monitoring & Risk Overview
- Behavioral & Peer Analytics
- Case Management & Investigation

Power BI connects **directly to MySQL through ODBC**, independent of the FastAPI backend.

---

# 🏗️ Architecture

<p align="center">
<img src="docs/architecture_diagram.png" width="750">
</p>

The platform consists of two independent consumers sharing the same MySQL database.

```
                Power BI
                    │
                ODBC Connection
                    │
                    ▼

             MySQL Database
      (Schema + Procedures + Views)

          ▲                     ▲
          │                     │

     FastAPI Backend        Stored Procedures

          │
          ▼

 Investigation Workspace
   (Jinja2 HTML Frontend)
```

---

# 🛠️ Tech Stack

| Layer | Technology |
|--------|------------|
| Backend | FastAPI |
| Language | Python |
| Database | MySQL |
| Authentication | JWT |
| Frontend | Jinja2 Templates |
| Analytics | Power BI |
| Deployment | Railway |
| API Docs | Swagger UI |

---

# 📂 Project Structure

```
AML-Analytics-Platform/

│
├── app/
│   ├── core/
│   ├── repositories/
│   ├── routers/
│   ├── schemas/
│   ├── services/
│   ├── templates/
│   └── web_auth.py
│
├── database/
│   ├── schema/
│   ├── procedures/
│   └── seed/
│
├── dashboards/
│
├── docs/
│
└── requirements.txt
```

---

# ⚙️ Installation

## Clone

```bash
git clone <repository-url>

cd AML-Analytics-Platform
```

## Install

```bash
pip install -r requirements.txt
```

## Configure

Create a `.env`

```env
DB_HOST=...
DB_PORT=3306
DB_USER=...
DB_PASSWORD=...
DB_NAME=aml_analytics

JWT_SECRET_KEY=your_secret_key
```

---

## Database Setup

Execute SQL files in order:

```
database/schema/
```

↓

```
database/procedures/
```

↓

```
database/seed/seed_data.sql
```

---

## Run

```bash
uvicorn app.main:app --reload
```

---

# 📸 Screenshots

## Investigation Workspace

### Login

> ![Login](image-3.png)

---

### Transaction Explorer

> ![Tranaction_page](image.png)

---

### Transaction Details

> ![Transaction_Details](image-1.png)

---

### Case Queue

> ![Case_Queue](image-2.png)

---

## Power BI Dashboards

### Dashboard 1

> ![Dashboard1_Transaction Monitoring & Risk Overview](<dashboards/Dashboard1_Transaction Monitoring & Risk Overview.png>)

---

### Dashboard 2

>![Dashboard2_Behavioral & Peer Analytics](<dashboards/Dashboard2_Behavioral & Peer Analytics.png>) 

---

### Dashboard 3

> ![Dashboard3_Case Management & Investigation](<dashboards/Dashboard3_Case Management & Investigation.png>)

---

# 🔒 Security

- Passwords hashed using **bcrypt**
- JWT authentication
- Role-based authorization
- Stored procedures validate business rules
- Repository pattern prevents raw business SQL

---

# 🚀 Deployment

Backend and database are deployed on **Railway**.

The application includes:

- REST API
- Swagger Documentation
- Web Investigation Workspace
- Railway MySQL Database

---

# 🔮 Future Improvements

- CSV/PDF report export
- Automated test suite
- Docker support
- CI/CD pipeline
- Email notifications
- Advanced anomaly detection models

---

# 👨‍💻 Author

**Jay**

Built as a portfolio project demonstrating backend engineering, database design, behavioral analytics, and dashboard development.

---

# ⭐ If you found this project interesting, consider giving it a star!