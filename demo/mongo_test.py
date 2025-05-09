import pymongo
from pymongo import MongoClient

# Connection string (replace with your actual string)
connection_string = "mongodb+srv://demetriuskcurry:UMGCgoCASAproject@projectschool.coi5v.mongodb.net/realestate?retryWrites=true&w=majority&appName=ProjectSchool"

client = MongoClient(connection_string)
db = client["realestate"]
collection = db["ForRent"]

results = collection.find().limit(5)

for document in results:
    print(document)

client.close()