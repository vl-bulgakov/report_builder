import pandas as pd
import pathlib as Path
import os
import subprocess
import psycopg2
import time
from decouple import config

def upload():
    credentials = {
        'dbname': config('POSTGRES_DB', default='reports'),
        'user': config('POSTGRES_USER', default='postgres'),
        'password': config('POSTGRES_PASSWORD', default='postgres'),
        'host': config('POSTGRES_HOST', default='db'),
        'port': config('POSTGRES_PORT', default='5432')
    }
    cursor = None
    conn = None
    
    time.sleep(10)

    # тут в будущем можно добавить циклом выбор нескольких файлов разных структур для дальнейшего построения нескольких 
    # нескольких витрин разных видов в базе
    try:
        copy_sql = "COPY public.claims_sample_data FROM STDIN DELIMITER ',' CSV HEADER"
        csv_file_path = os.path.abspath('/usr/src/app/src/claims_sample_data.csv')

        conn = psycopg2.connect(**credentials)
        cursor = conn.cursor()

        with open(csv_file_path, 'r') as f:
            cursor.execute("truncate table public.claims_sample_data;")
            cursor.copy_expert(sql=copy_sql, file=f)
            conn.commit()
            
        print("Data imported successfully")

        # Вызов хранимой процедуры fn_create_tables() для построение широких витрин для дальнейшей визуализации
        # их тоже планируется несколько, так как проект планируется под масштабирование 
        cursor.execute("SELECT fn_create_tables();")
        conn.commit()
        print("fn_create_tables() successfully")


        #выгрузка построившихся витрин в папку для дальнейшего использования в построении отчета\ов
        mv_agg_amounts_dds_query = "SELECT * FROM mv_agg_amounts_dds;"
        mv_agg_forecast_query = "SELECT * FROM mv_agg_forecast;"
        df_mv_agg_amounts_dds = pd.read_sql(mv_agg_amounts_dds_query, conn)
        df_mv_agg_forecast = pd.read_sql(mv_agg_forecast_query, conn)
        df_mv_agg_amounts_dds.to_csv('/usr/src/app/src/mv_agg_amounts_dds.csv', index=False)
        df_mv_agg_forecast.to_csv('/usr/src/app/src/mv_agg_forecast.csv', index=False)


        # Для запуска построения отчетов пока используется просто запуск скрипта из path, так как в дальнейшем
        # количество этих скриптов может быть большим для отстройки других отчетов, пока не придумал, как это можно будет реализовать 
        # вызовом функций. Возможно надо будет переходить к ооп для класса отдельного для каждого отчета
        script_path = '/usr/src/app/app_dash.py'

        # Запуск скрипта
        subprocess.run(['python', script_path])
        

    except Exception as e:
        print("Error:", e)

    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

if __name__ == '__main__':
    upload()