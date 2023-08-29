English version:

The task is implemented as a microservice (worker + database) that takes a file of a specified format as input and generates interactive tables and graphs using Dash, which you can access in your web browser.

Deployment is done via the following command in the terminal from the "report_builder" directory:
Type:

    docker compose up -d
    
Then press Enter.

Here's an example of how it should look in the command line:

    ...\Desktop\Test\Medicine\report_app> docker compose up -d

To access the report, you need to open the link http://localhost:5000/ in your browser. Choose the file (claims_sample_data.csv), then click "Apply Changes".

If the port is occupied by something else, let me know, and I can change the port for you.

In the report, you need to select the aggregation level that you're interested in for aggregated data. You can then manipulate the filters according to your requirements. The buttons allow you to choose the value that is displayed on the screen (sum, average, payment count, debt count, number of missing service type values).

The same applies to predictions. You choose the aggregation level and other filters, then use the buttons to select the type of forecast you want to generate (I've implemented several). A line will be displayed above the bars to show the real values, allowing you to compare the forecast accuracy from the previous instances. The forecast deviation is calculated where possible and typically ranges between 15-22% across all data. Providing more data can lead to improved accuracy.

The data is prepared in the format of wide tables in the database (you can see the file in the "database/01_init.sql" directory), and the dates are standardized.

Future scalability of the service includes:

Adding the capability to generate other types of reports.
Implementing user-specific access controls in the database.
Developing functions to output statistics about the number of reports, historical storage, etc.



Russian version:

Задача реализована в виде микросервиса (воркер+БД), который получает на вход файл заданного вида и строит 
интерактивные таблицы и графики в Dash, который вы можете открыть в вашем браузере.

Развертывание происходит командой в терминале из директории report_app: 
Напишите

    docker compose up -d
    
И нажмите Enter

Пример, как должно выглядеть в командной строке:

    ...\Desktop\Тестовые\Medicine\report_app> docker compose up -d

Чтобы открыть отчет вам нужно перейти по ссылке http://localhost:5000/ 
Выберите файл (claims_sample_data.csv), нажмите Apply Changes.

Если у вас этот порт занят чем то другим - дайте знать, я поменяю порт. 

В отчете вам необходимо выбрать уровень агрегации, по которому вас интеерсуют агрегированные данные и дальше манипулируйте с фильтрами по вашей необходимости. Кнопочки выбирают значение, которое выводится на экран(сумма, среднее, количество платежей, количество долгов, сколько незаполненных значений вида услуги).

То же самое по предиктам. Выбираете уровень агрегации, другие фильтры и кнопочками выбираете вид форкаста, который надо построить (реализовал несколько). Линией над барами будут идти реальные значения, чтобы можно было посмотреть, угадывал ли прогноз в прошлый раз. Отклонение прогноза посчитано по возможности, составляет около 15-22% в общем по всем данным. Дайте больше данных - сделаю точнее.

Данные подготовлены в формате широких витрин в базе данных (можно посмотреть в файле в директории database/01_init.sql), даты приведены в единый формат.


Дальнейшее масштабирование сервиса:
Добавление построения других отчетов
Реализация в базе данных доступов по пользователям, функций для вывода статистики по количеству отчетов, историчного хранения и т д

