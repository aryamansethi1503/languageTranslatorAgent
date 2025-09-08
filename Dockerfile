# Use an official lightweight Python image
FROM python:3.11-slim

# Set the working directory inside the container
WORKDIR /app

# Copy the requirements file and install dependencies
# This is done first to leverage Docker's layer caching
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of your application files into the container
COPY . .

# Expose the port Streamlit will run on
EXPOSE 8080

# The command to run your app when the container starts
# The flags are important for running in a cloud environment
CMD exec streamlit run translatorAgent.py --server.port=$PORT --server.address=0.0.0.0 --server.headless=true --server.enableCORS=false