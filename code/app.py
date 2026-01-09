from flask import Flask, render_template, request
from prometheus_flask_exporter import PrometheusMetrics
import os
import time
import socket

a_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)


app = Flask(__name__)
metrics = PrometheusMetrics(app)

ID = os.environ['ID']


import mysql.connector



def isMysqlUp():
    port = 3306
    location = (os.environ['MYSQL_HOST'], port)
    while True:
        check = a_socket.connect_ex(location)
        if check == 0:
            print("Port is open")
            break
        else:
            print("Port is not open")
        time.sleep(2.4)
        

isMysqlUp()


mydb = mysql.connector.connect(
  host=os.environ['MYSQL_HOST'],
  user=os.environ['MYSQL_USER'],
  password=os.environ['MYSQL_PASSWORD'],
  database=os.environ['MYSQL_DATABASE']
)



@app.route('/')
def hello_world():
    #Get the data from sql
    mycursor = mydb.cursor()
    mycursor.execute("SELECT * FROM targets")
    myresult = mycursor.fetchall()
    for target in myresult:
        print(target)

    return render_template('home.html',targets=myresult)

@app.route('/target', methods=['PUT'])
def add_targets():
    if request.is_json:
        content = request.get_json()
        target = content['target']
        tag = content['tag']
        mycursor = mydb.cursor()
        sql = "INSERT INTO `targets` (`target`, `tag`) VALUES (%s, %s)"
        val = (target, tag)
        mycursor.execute(sql, val)
        mydb.commit()
        return("Targets added")
    else:
        return("No jason buuuu ")



@app.route('/target', methods=['DELETE'])
def delete_targets():
    if request.is_json:
        content = request.get_json()
        id = content['id']
        mycursor = mydb.cursor()
        # Fixed: Use parameterized query to prevent SQL injection
        sql = "DELETE FROM targets WHERE id = %s"
        mycursor.execute(sql, (id,))
        mydb.commit()
        return("Row deleted")
    else:
        return("No jason buuuu ")



#
# This is the check to keep the pod alive
# if this fails k8s will restart the pod
@metrics.do_not_track()
@app.route('/health')
def health():
    return 'Everything is Good!'

#
# This is the check that lets the pod accepts trafffic
# if this fails k8s will not send any more traffic to this pod
@metrics.do_not_track()
@app.route('/ready')
def ready():
    return 'Im ready to work!'


#
# /metrics endpint is alive and send prometheus metrics
#  
#
#