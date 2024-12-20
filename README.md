# Image Ranking Web App

<img src="/readme-stuff/image_ranker.png" alt="Project Image" width="200" height="200" />


This repository hosts the code for a web application that integrates **AWS DynamoDB** and **AWS S3** to store and rank images. Users can upload images, and then vote on their favorites. The rankings are stored in DynamoDB, and images are efficiently served from S3.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)


## Prerequisites

- **Python 3.9** or later
- **pip** (Python package installer)
- **AWS Credentials** with access to DynamoDB and S3
- (Optional) **Virtual environment** management tool like `venv` or `virtualenv`

## Installation

1. **Clone the Repository:**
   ```bash
   git clone https://github.com/therealadityashankar/assignment_DLBSEPCP01_E.git
   cd assignment_DLBSEPCP01_E
   ```

2. **Set Up Virtual Environment (Recommended):**
   ```bash
   python3.9 -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install Dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

## Configuration

1. **AWS Credentials:**  
   Ensure your environment is configured with AWS credentials that have permission to read/write to DynamoDB and S3. For instance, you can set up `~/.aws/credentials` or use environment variables:
   ```bash
   export AWS_ACCESS_KEY_ID=your_access_key_id
   export AWS_SECRET_ACCESS_KEY=your_secret_access_key
   export AWS_DEFAULT_REGION=your_preferred_region
   ```

2. **Environment Variables:**  
   Create a `.env` file (or similar configuration file) to store environment variables:
   ```bash
   DYNAMODB_TABLE_NAME=your_table_name
   S3_BUCKET_NAME=your_bucket_name
   ```

## Usage

1. **Run the Application:**
   ```bash
   python app.py
   ```
   
2. **Access via Browser:**
   Open `http://localhost:5000` in your web browser.  
   - Upload images via the "Upload" page.
   - Vote for your favorite images on the "Rank" page.
   - View the leaderboard to see which images are on top!
