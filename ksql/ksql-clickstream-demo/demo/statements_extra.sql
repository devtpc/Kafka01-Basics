
---------------------------------------------------------------------------------------------------
-- Build materialized table views:
---------------------------------------------------------------------------------------------------

-- Per-userId tables -----------------------------------------------------------------------------

-- Table of events per minute for each user:
DROP TABLE events_per_min;
CREATE table events_per_min AS
    SELECT
        userid as k1,
        AS_VALUE(userid) as userid,
        WINDOWSTART as EVENT_TS,
        count(*) AS events,
        sum(bytes) AS bytes
    FROM clickstream window TUMBLING (size 60 second)
    GROUP BY userid;



-- Table counts number of events within the session
DROP TABLE CLICK_USER_SESSIONS;
CREATE TABLE CLICK_USER_SESSIONS AS
    SELECT
        username as K,
        AS_VALUE(username) as username,
        WINDOWEND as EVENT_TS,
        count(*) AS events,
        sum(bytes) AS bytes
    FROM USER_CLICKSTREAM window SESSION (30 second)
    GROUP BY username;
