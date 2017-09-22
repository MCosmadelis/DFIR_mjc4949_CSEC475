"""
VirusTotal Uploads/Reports
Author: Michael Cosmadelis
"""

import requests 
import smtplib
import pprint
import sys

APIkey = raw_input("Enter API key: ")
params = {'apikey': APIkey}

	
def getFileReport(id):
	params = {'apikey': APIkey, 'resource': id}
	headers = {
	"Accept-Encoding": "gzip, deflate",
        "User-Agent" : "gzip,  My Python requests library example client or username"
	}
	response = requests.get('https://www.virustotal.com/vtapi/v2/file/report',
	params=params, headers=headers)
	return response.json()

def getURLReport(url):
	headers = {
	"Accept-Encoding": "gzip, deflate",
        "User-Agent" : "gzip,  My Python requests library example client or username"

	}
	params = {'apikey': APIkey, 'resource':url}
	response = requests.post('https://www.virustotal.com/vtapi/v2/url/report',
	params=params, headers=headers)
	return response.json()

def uploadFile(id):
	files = {'file': (id, open(id, 'rb'))}
	response = requests.post('https://www.virustotal.com/vtapi/v2/file/scan', files=files, params=params)
	return response.json()

def uploadURL(id):
	params = {'apikey': APIkey, 'url': id}
	response = requests.post('https://www.virustotal.com/vtapi/v2/url/scan', data=params)
	return response.json()

# argument handling
if sys.argv[1] == "-uploadurl":
	try:
		uploadURL(sys.argv[2])
		print("URL has been submitted.\n Execute '{}' -urlresults '{}' to view the results".format(sys.argv[0], sys.argv[2]))
	except Exception:
		print("URL submission failed.")
elif sys.argv[1] == "-uploadfile":
	try:
		name = uploadFile(sys.argv[2])
                name = name['resource']
		print("File has been submitted. Execute '{}' -fileresults '{}' to view the results".format(sys.argv[0], name))
        except Exception:
		print("File submission failed")
elif sys.argv[1] == "-urlresults":
	try:
            results = getURLReport(sys.argv[2])['scans']
	    print(results)
        except Exception:
		print("Obtaining URL report failed")
elif sys.argv[1] == "-fileresults":
	try:
            results = getFileReport(sys.argv[2])['scans']
	    print(results)
        except Exception:
		print("Obtaining file report failed")

# Email report from Gmail account
if sys.argv[3] == "-email":
    try:
        gmail_user = raw_input("Gmail username: ")
        gmail_pass = raw_input("Gmail password: ")
        server = smtplib.SMTP("smtp.gmail.com", 587)
        to = raw_input("Enter recipient email: ")
        server.ehlo()
        server.starttls()
        server.login(gmail_user, gmail_pass)
        
        sent_from = gmail_user
        body = results
        
        server.sendmail(sent_from, to, body)
        server.close()
    except Exception:
        print("Error: Unable to send")


