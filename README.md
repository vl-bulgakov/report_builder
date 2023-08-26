English version:

The task is implemented as a microservice (worker + database) that takes a specific type of input file and constructs interactive tables and graphs using Dash, which you can open in your web browser.

Deployment is done by running a command in the terminal from the "report_builder-main" directory (the data file claims_sample_data.csv is already located in the "app/src/" directory): 
    
    Command "docker compose up -d" and press Enter.

An example of how it should look in the command line: 

    ...\Desktop\Test\Medicine\report_builder-main> docker compose up -d

You can view the generated dashboard in your browser after launching all containers and services (note that it might take at least 10 seconds after launching the "app" container, as there is a timer in place to ensure all database structures have been properly set up).

To access the report, you need to go to the link http://localhost:8050/. If this port is already in use, please let me know, and I will change the port or you can do it yourself in the Docker Compose file: the following lines:

    ports:
      - '8050:8050' -- here, you should change the second number to an available port, for example, 8050:8080

n the report, you need to select the aggregation level for which you are interested in aggregated data, and then manipulate the filters as needed. The buttons select the value that is displayed on the screen (sum, average, count of payments, count of debts, number of missing service type values).

The same applies to forecasts. You choose the aggregation level, apply other filters, and use the buttons to choose the type of forecast to be displayed (I have implemented several). A line will be displayed above the bars showing actual values, allowing you to see how accurate the previous forecast was. The forecast deviation is calculated whenever possible and averages around 15-22% across all data. If you provide more data, I can make it more accurate.

The data is prepared in the format of wide tables in the database (you can see the details in the file "database/01_init.sql"), and the dates are standardized.

"app.py" reads the "claims_sample_data.csv" file from the "app/src/" directory, performs manipulations in the database, and exports the resulting tables to the "app/src/" directory. It also runs the following script: "app_dash.py" reads the files and constructs graphs in Dash.

Future scalability of the service includes: Adding the ability to generate other types of reports, adding a file upload window in the browser, implementing user-based access control in the database, functions for reporting on the number of generated reports, historical storage, etc.



Russian version:

Задача реализована в виде микросервиса (воркер+БД), который получает на вход файл заданного вида и строит 
интерактивные таблицы и графики в Dash, который вы можете открыть в вашем браузере.

Развертывание происходит командой в терминале из директории report_app (файл с данными claims_sample_data.csv уже лежит в директории app/src/): 
Напишите

    docker compose up -d
    
И нажмите Enter

Пример, как должно выглядеть в командной строке:

    ...\Desktop\Тестовые\Medicine\report_app> docker compose up -d

Посмотреть построенный дашборд вы можете в браузере после запуска всех контейнеров и сервисов (учтите, что не ранее 10 секунд после запуска контейнера app, так как стоит таймер на случай, если не все структуры в базе данных успели равернуться)

Чтобы открыть отчет вам нужно перейти по ссылке http://localhost:8050/ 

Если у вас этот порт занят чем то другим - дайте знать, я поменяю порт 
или сделайте это сами в докер-компоуз файле:
строки  
 
    ports:
      - '8050:8050' --тут надо поставить на ваш свободный во второе число, например 8050:8080
 

В отчете вам необходимо выбрать уровень агрегации, по которому вас интеерсуют агрегированные данные и дальше манипулируйте с фильтрами по вашей необходимости. Кнопочки выбирают значение, которое выводится на экран(сумма, среднее, количество платежей, количество долгов, сколько незаполненных значений вида услуги).

То же самое по предиктам. Выбираете уровень агрегации, другие фильтры и кнопочками выбираете вид форкаста, который надо построить (реализовал несколько). Линией над барами будут идти реальные значения, чтобы можно было посмотреть, угадывал ли прогноз в прошлый раз. Отклонение прогноза посчитано по возможности, составляет около 15-22% в общем по всем данным. Дайте больше данных - сделаю точнее.

Данные подготовлены в формате широких витрин в базе данных (можно посмотреть в файле в директории database/01_init.sql), даты приведены в единый формат.

app.py - запускает чтение файла claims_sample_data.csv из директории app/src/ , манипуляции в базе данных и выгрузку результирующих витрин в app/src/  так же запускает следующий скрипт:
app_dash.py - считывает файлы и строит графики в Dash


Дальнейшее масштабирование сервиса:
Добавление построения других отчетов
Добавление окна в браузере для загрузки файла
Реализация в базе данных доступов по пользователям, функций для вывода статистики по количеству отчетов, историчного хранения и т д

