import os
import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore

# Use the application default credentials
cred = credentials.Certificate('/Users/toyokawaren/GitHub/py_scraping/calorie.slism.jp/DietMenu-bbec33de6b70.json')
firebase_admin.initialize_app(cred)

db = firestore.client()
doc_ref = db.collection(u'food_materials').document()
doc_ref.set() 

