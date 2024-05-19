# Kafka Basics Homework

## Introduction

This project is a homework at the EPAM Data Engineering Mentor program. The project mainly requires to follow a tutorial with some extra steps, and documenting the results. The description form the original readme:

This example shows how KSQL can be used to process a stream of click data, aggregate and filter it, and join to information about the users.
Visualisation of the results is provided by Grafana, on top of data streamed to Elasticsearch. 

You can find the documentation for running this example and its accompanying tutorial at [https://docs.confluent.io/platform/current/tutorials/examples/clickstream/docs/index.html](https://docs.confluent.io/platform/current/tutorials/examples/clickstream/docs/index.html?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clickstream)

This description follows the above tutorial from [Confluent](https://www.confluent.io/), the original copyright belongs to them

## Going through the tutorial

### Startup

Although there is a `./start.sh` command available to start everything as a whole, the tutorial suggests to go step-by-step and observe the intermediate steps.

1. Get the Jar files for `kafka-connect-datagen` (source connector) and `kafka-connect-elasticsearch` (sink connector).

```
docker run -v $PWD/confluent-hub-components:/share/confluent-hub-components confluentinc/ksqldb-server:0.8.0 confluent-hub install --no-prompt confluentinc/kafka-connect-datagen:0.4.0
docker run -v $PWD/confluent-hub-components:/share/confluent-hub-components confluentinc/ksqldb-server:0.8.0 confluent-hub install --no-prompt confluentinc/kafka-connect-elasticsearch:10.0.2
```

![Startup 1 image](/screenshots/img_startup_1.png)

2. Launch the tutorial in Docker.
```
docker-compose up -d
```
![Startup 2 image](/screenshots/img_startup_2.png)

3. After a minute or so, run the `docker-compose ps` status command to ensure that everything has started correctly.

![Startup 3 image](/screenshots/img_startup_3.png)

### Create the Clickstream Data

> [!NOTE]
> Although that most of the scripts could be run in the Gitbash shell on windows, the `ksql` commands and scripts did not run properly, so I changed the environment to the WSL (Windows Subsystem for Linux) terminal, where everything worked smoothly.

1. Launch the ksqlDB CLI:
```
docker-compose exec ksqldb-cli ksql http://ksqldb-server:8088
```
![Start ksql cli](/screenshots/img_create_cs_1.png)

2. Ensure the ksqlDB server is ready to receive requests by running the following until it succeeds:
```
show topics;
```
After a few minutes this is shown:

![show topics img](/screenshots/img_create_cs_2.png)

3. Run the script `create-connectors.sql` that executes the ksqlDB statements to create three source connectors for generating mock data.
```
RUN SCRIPT '/scripts/create-connectors.sql';
```
![create connectors img](/screenshots/img_create_cs_3.png)

4. Now the clickstream generator is running, simulating the stream of clicks. Sample the messages in the clickstream topic:
```
print clickstream limit 3;
```
![print clickstream img](/screenshots/img_print_clickstream.png)

5. The second data generator running is for the HTTP status codes. Sample the messages in the clickstream_codes topic:
```
print clickstream_codes limit 3;
```
![print clickstream codes img](/screenshots/img_print_clickstream_codes.png)

6. The third data generator is for the user information. Sample the messages in the clickstream_users topic:
```
print clickstream_users limit 3;
```
![print clickstream users img](/screenshots/img_print_clickstream_users.png)

7. Go to Confluent Control Center UI at http://localhost:9021 and view the three kafka-connect-datagen source connectors created with the ksqlDB CLI.

![Control center connectors img](/screenshots/img_cc_connectors_1.png)

### Load the Streaming Data to ksqlDB

Load the statements.sql file that runs the tutorial app.
```
RUN SCRIPT '/scripts/statements.sql';
```
The script creates many tables, here is the end of the script output on the console:

![Load streaming data to ksql db img](/screenshots/img_load_streaming_to_ksqldb.png)

### Verify the data

1. Go to Confluent Control Center UI at http://localhost:9021, and view the ksqlDB view `Flow`.

![Verify data 1 img](/screenshots/img_verify_data_1.png)

2. Verify that data is being streamed through various tables and streams. Query one of the streams `CLICKSTREAM`:

![Verify data 2 img](/screenshots/img_verify_data_2.png)

### Load the Clickstream Data in Grafana

1. Set up the required Elasticsearch document mapping template:
```
docker-compose exec elasticsearch bash -c '/scripts/elastic-dynamic-template.sh'
```
![Verify grafana 1 img](/screenshots/img_verify_grafana_1.png)

2. Run this command to send the ksqlDB tables to Elasticsearch and Grafana:
```
docker-compose exec ksqldb-server bash -c '/scripts/ksql-tables-to-grafana.sh'
```

The output is long, here is the end of the output on the console:

![Verify grafana 2 img](/screenshots/img_verify_grafana_2.png)

3. Load the dashboard into Grafana.
```
docker-compose exec grafana bash -c '/scripts/clickstream-analysis-dashboard.sh'
```

![Verify grafana 3 img](/screenshots/img_verify_grafana_3.png)

4. Navigate to the Grafana dashboard at http://localhost:3000. Enter the username and password as `user` and `user`. Then navigate to the `Clickstream Analysis Dashboard`.

![Verify grafana 4 img](/screenshots/img_verify_grafana_4.png)

5. In the Confluent Control Center UI at http://localhost:9021, again view the running connectors. The three kafka-connect-datagen source connectors were created with the ksqlDB CLI, and the seven Elasticsearch sink connectors were created with the ksqlDB REST API.

![Verify grafana 5 img](/screenshots/img_verify_grafana_5.png)

### Sessionize the data

One of the tables created by the demo, CLICK_USER_SESSIONS, shows a count of user activity for a given user session. All clicks from the user count towards the total user activity for the current session. If a user is inactive for 30 seconds, then any subsequent click activity is counted towards a new session.

The clickstream demo simulates user sessions with a script. The script pauses the DATAGEN_CLICKSTREAM connector every 90 seconds for a 35 second period of inactivity. By stopping the DATAGEN_CLICKSTREAM connector for some time greater than 30 seconds, you will see distinct user sessions.

You’ll probably use a longer inactivity gap for session windows in practice. But the demo uses 30 seconds so you can see the sessions in action in a reasonable amount of time.

Session windows are different because they monitor user behavior and other window implementations consider only time.

To generate the session data execute the following statement from the examples/clickstream directory:
```
./sessionize-data.sh
```

Navigate to the Grafana dashboard at http://localhost:3000. Enter the username and password as `user` and `user`. Then navigate to the `Clickstream Analysis Dashboard`.

We can see on the Dashboard that after some time elapses, the data are changing to sessionized.

![Sessionize 1](/screenshots/img_sessionize_1.png)

![Sessionize 2](/screenshots/img_sessionize_2.png)

## Other tasks

The original task requires that metrics about the following should be shown and calculated:

* General website analytics, such as hit count and visitors
* Bandwidth use
* Mapping user-IP addresses to actual users and their location
* Detection of high-bandwidth user sessions
* Error-code occurrence and enrichment
* Sessionization to track user-sessions and understand behavior (such as per-user-session-bandwidth, per-user-session-hits etc)

Most of these data, except for the bandwidth-related data are included in the original dashboard.

### Data on original Dashboard

#### General website analytics, such as hit count and visitors

The general metrics are all over the dashboard. The following image shows Page views and events, the other metrics are displayed under the later subheadings

![Metrics general 1](/screenshots/img_metrics_general_1.png)


#### Mapping user-IP addresses to actual users and their location

On the top-right corner of the original dashboard

![Metrics user ip](/screenshots/img_metrics_userip.png)

#### Error-code occurrence and enrichment

Normal chart with error-codes is at the top-left of the original dashboard, while error-code occurrence and enrichment are at the bottom-left table.

![Metrics error 1](/screenshots/img_metrics_error_1.png)

![Metrics error 2](/screenshots/img_metrics_error_2.png)

#### Sessionization to track user-sessions and understand behavior (such as per-user-session-bandwidth, per-user-session-hits etc)

The per-user-session-hits are at the middle of the original dashboard.

![Metrics session 1](/screenshots/img_metrics_session_1.png)

### Extra data

As mentioned before, most of the data are included in the original dashboard. However these bandwidth-related data are not included in the original dashboard:

* Bandwidth use
* Detection of high-bandwidth user sessions
* Party included: Sessionization to track user-sessions and understand behavior (such as per-user-session-bandwidth, per-user-session-hits etc)

#### Getting the extra data

If we examine carefully the original data sources, the byte usage data are included in the original `clickstream` data, and also in the `USER_CLICKSTREAM` data, however, they are not carried forward to the other materialized table views, and the Elasticsearch data.

To get the data, we correct the tables, adding the `sum(bytes)` metric to the corresponding tables
```
DROP TABLE events_per_min;
CREATE table events_per_min AS
    SELECT
        userid as k1,
        AS_VALUE(userid) as userid,
        WINDOWSTART as EVENT_TS,
        count(*) AS events
-- the following line is added to the original
        , sum(bytes) AS bytes
    FROM clickstream window TUMBLING (size 60 second)
    GROUP BY userid;



-- Table counts number of events within the session
DROP TABLE CLICK_USER_SESSIONS;
CREATE TABLE CLICK_USER_SESSIONS AS
    SELECT
        username as K,
        AS_VALUE(username) as username,
        WINDOWEND as EVENT_TS,
        count(*) AS events
-- the following line is added to the original
        , sum(bytes) AS bytes
    FROM USER_CLICKSTREAM window SESSION (30 second)
    GROUP BY username;
```

The above code was created as a [statemens_extra.sql](/ksql/ksql-clickstream-demo/demo/statements_extra.sql) file. Note, that this file was not included in the original tutorial.

Run this script from the `ksql shell` by running
```
RUN SCRIPT '/scripts/statements.sql';
```

Repeat the tutorial steps from the [Load the Clickstream Data in Grafana](#load-the-clickstream-data-in-grafana) task!

#### Creating the extra panels on the dashboard

On the Grafana dashboard we add two extra panels.

First, we create a new panel, and copy the settings of the `User Sessionisation - resource hits` panel, however we use the `Bytes` as a metric, instead of `Events`. Note, that this was not in the original `click_user_sessions` table, only now, that we modified it.

![Metrics new create 1](/screenshots/img_newmetrics_create_1.png)

We create another panel, and copy the settings of the `Count all Events grouped by time bucket` panel, however we use the `Bytes` as a metric, instead of `Events`. Note, that this was not in the original `events_per_min`, table, only now, that we modified it.

![Metrics new create 2](/screenshots/img_newmetrics_create_2.png)

#### New data is displayed

Observe, that the new metrics data are shown on the dashboard

![Metrics new 1](/screenshots/img_newmetrics_display_1.png)


