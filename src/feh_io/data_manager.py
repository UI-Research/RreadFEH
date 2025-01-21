import json
import requests
import os
import time

class DataManager:

    def __init__(self):
        self.url_base = "https://dynasim-data-manager.urban.org/api/"

        self.user_token = None
        self.headers = None

    def connect(self, user_account, password):
        # set credentials and retrieve token
        user_account = {
            "email": user_account,
            "password": password 
        }
        r = requests.post(f"{self.url_base}users/login/", data=user_account)
        self.user_token = r.json()["token"]

        self.headers = {"Authorization": f"Token {self.user_token}"}
    
    def get_projects(self):
        response = requests.get(f"{self.url_base}/projects/", headers=self.headers)
        return response.json()

    def get_project(self, project_id):
        response = requests.get(f"{self.url_base}/projects/{project_id}", headers=self.headers)
        return response.json()

    def get_scenarios(self):
        response = requests.get(f"{self.url_base}/scenarios/", headers=self.headers)
        return response.json()

    def get_scenarios_for_project(self, project_id):
        response = requests.get(f"{self.url_base}/projects/{project_id}/scenarios/", headers=self.headers)
        return response.json()

    def get_variables_for_project(self, project_id):
        response = requests.get(f"{self.url_base}/projects/{project_id}/variables/", headers=self.headers)
        return json.loads(json.loads(response.text))

    def generate_dataset(self, project_name, scenarios, family_variables=[], person_variables=[],
        birth_year_range=[], year_range=[]):
        if not isinstance(scenarios, list):
            print("ERROR: scenarios must be an array.")
            return
        if len(family_variables)==0 and len(person_variables) == 0:
            print("ERROR: must specify at least one of family_variables or person_variables.")
            return None       
        if (not isinstance(family_variables, list) and not isinstance(person_variables, list)):
            print("ERROR: family and person variables must be an array.")
            return None
        if (not isinstance(birth_year_range, list)):
            print("ERROR: birth_year_range must be an array.")
            return
        if (not isinstance(year_range, list)):
            print("ERROR: year_range must be an array.")
            return
        # Download a subset of data
        # sample payload
        payload = {
            "project_name": project_name,
            "scenarios": scenarios,
            "person_variables": person_variables,
            "family_variables": family_variables,
            "birth_year_range": birth_year_range,
            "year_range": year_range
        }

        try:
            response = requests.post(f"{self.url_base}generate-dataset/", headers=self.headers, json=payload)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.HTTPError as e:
            raise e

    def get_dataset_status(self, job_id, file_type): 

        try:
            response = requests.get(f"{self.url_base}/dataset-status/{job_id}/{file_type}", headers=self.headers)
        except requests.exceptions.HTTPError as e:
            print(e)

        return response.json()

    def download_file(self, presigned_url, output_path):
        data_type = ""
        if "family" in presigned_url:
            data_type = "Family"
        elif "person" in presigned_url:
            data_type = "Person"

        if not output_path.endswith(('.zip', '.pq')):
            raise Exception("Output path must use either .zip or .pq")

        try:
            response = requests.get(presigned_url)
            response.raise_for_status()
            if response.status_code == 200:
                with open(output_path, "wb") as file:
                    file.write(response.content)
                if data_type:
                    print(f"{data_type} file successfully downloaded.")
                else:
                    print("File successfully downloaded.")
        except Exception as e:
            print(e)
            print(f"Failed to download file")
    
    def request_and_download_datasets(self, output_dir, file_type, project_name, scenarios,
        family_variables=[], person_variables=[], birth_year_range=[], year_range=[]):
        print("Generating request...")

        if not os.path.exists(output_dir):
            print("Error: Does the provided output dir exist?")
            return False

        if file_type not in ["csv", "parquet"]:
            print("Error: Please provide a valid file type (`csv` or `parquet`)")
            return False

        try:
            response = self.generate_dataset(
                project_name,
                scenarios,
                person_variables=person_variables,
                family_variables=family_variables,
                birth_year_range=birth_year_range,
                year_range=year_range
            )
        except Exception as e:
            print("generate_dataset() failed. Please try again.")
            raise e

        job_id = response.get('job_id')
        print(f"Job successfully submitted. Job ID: {job_id}")

        print("Checking status...")
        job_status = "PENDING"
        timeout = 10 * 60  # time out after 10 min
        start_time = time.time()

        while job_status != "SUCCEEDED": 
            time.sleep(5)
            response1 = self.get_dataset_status(job_id, file_type)
            job_status = response1['job_status']
            print(job_status)
            if job_status in ["STOPPED", "FAILED", "ERROR", "TIMEOUT"]:
                print(response1['message'])
                print(f"ERROR: Glue job failed with status {job_status}")
                return False

            elapsed_time = time.time() - start_time
            if elapsed_time > timeout:
                print(f"Timeout reached after 10 min. Stopping program for job id {job_id}.")
                break
    
        if ('family_url' not in response1 and 'person_url' not in response1): # in case of timeout
            print("Could not retrieve URLs. Please try again or check back later.")
            return False
    
        family_url = response1['family_url']
        person_url = response1['person_url']

        if file_type == "csv":
            ext = "zip"
        elif file_type == "parquet":
            ext = "pq"

        self.download_file(family_url, f"{output_dir}/family_data.{ext}")
        self.download_file(person_url, f"{output_dir}/person_data.{ext}")

        return True