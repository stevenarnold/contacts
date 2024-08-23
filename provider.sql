/* Combine all provider tables */
CREATE OR replace table providers360all AS
     SELECT *
       FROM vc360all
      UNION ALL
     SELECT *
       FROM uhm360all
      UNION ALL
     SELECT *
       FROM prmg360all
      UNION ALL
     SELECT *
       FROM phh360all
      UNION ALL
     SELECT *
       FROM lfc360all
      UNION ALL
     SELECT *
       FROM fairway360all
      UNION ALL
     SELECT *
       FROM dart360all
      UNION ALL
     SELECT *
       FROM cms360all
      UNION ALL
     SELECT *
       FROM providers360all
;

ALTER TABLE providers360all ADD CONSTRAINT unique_pk UNIQUE(pk)
;

CREATE OR replace table providers360metadata AS
     SELECT uuid_string() AS pk
          , pk AS contactPK
          , lastModifiedDate AS freshness
          , CASE
              WHEN provider = 'vc' AND email LIKE '%villagecapital.com' THEN 1
              WHEN provider = 'prmg' AND email LIKE '%prmg.net' THEN 1
              WHEN provider = 'cms' AND email LIKE '%carringtonms.com' THEN 1
              WHEN provider = 'uhm' AND email LIKE '%uhm.com' THEN 1
              WHEN provider = 'phh' AND email LIKE '%phhmortgage.com' THEN 1
              WHEN provider = 'lfc' AND email LIKE '%loganfinance.com' THEN 1
              ELSE 0
          END AS provenance
       FROM providers360all
;

/* Create workspace table */
/* ( Note name change from dart to providers from this point forward ) */
CREATE OR REPLACE TABLE providersWork AS
    SELECT FILENAME
          , CONTACTOWNER
          , CONTACTOWNERALIAS
          , CREATEDBY
          , CREATEDALIAS
          , LASTMODIFIEDBY
          , LASTMODIFIEDALIAS
          , '' AS MIDDLENAME 
          , '' AS SUFFIX 
          , DEPARTMENT
          , BIRTHDATE
          , LEADSOURCE
          , ASSISTANT
          , ASST_PHONE
          , OWNERROLEDISPLAY
          , OWNERROLENAME
          , LASTACTIVITY
          , DESCRIPTION
          , LASTMODIFIEDDATE
          , CREATEDDATE
          , CONTACTID
          , REPORTSTO
          , LASTSTAY_IN_TOUCHREQUESTDATE
          , LASTSTAY_IN_TOUCHSAVEDATE
          , DATA_COMKEY
          , PRONOUNS
          , GENDERIDENTITY
          , SALUTATION
          , FIRSTNAME
          , LASTNAME
          , TITLE
          , ACCOUNTNAME
          , MAILINGSTREET
          , MAILINGCITY
          , MAILINGSTATE
          , MAILINGZIP
          , MAILINGCOUNTRY
          , PHONE
          , FAX
          , MOBILE
          , EMAIL
          , ACCOUNTOWNER
       FROM SANDBOX_SARNOLD.CONTACTS.providers360all
;

/* First Group: Email Cardinality */
CREATE OR REPLACE TABLE providers360_1 AS
     SELECT sha1(concat(contactID, lastModifiedDate)) AS pk
          , 'providers' AS provider
          , 1 AS sgroup
          , *
       FROM providersWork
      WHERE 1=1
        AND email IN (SELECT email
       FROM providersWork
    GROUP BY email
     HAVING count (*) = 1)
;

 DELETE
       FROM providersWork
      WHERE 1=1
        AND contactID IN (SELECT contactID
                             FROM providers360_1)
;

/* Second Group: Unique Firstname , Lastname , Account */
     CREATE OR REPLACE TABLE providers360_2 AS
     SELECT sha1(concat(contactID, lastModifiedDate)) AS pk
          , 'providers' AS provider
          , 2 AS sgroup
          , w.*
       FROM providersWork w
       JOIN (SELECT firstname
                  , lastname
                  , accountname
                  , count(*)
               FROM providersWork
           GROUP BY firstname
                  , lastname
                  , accountname
             HAVING count(*) = 1
            ) t
          ON w.firstname = t.firstname
        AND w.lastname = t.lastname
        AND w.accountname = t.accountname
;


DELETE
       FROM providersWork
      WHERE 1=1
        AND contactID IN (SELECT contactID
                             FROM providers360_2)
;

/* Third Group: Unique Firstname , Lastname , Account not by DataSync */
     CREATE OR REPLACE TABLE providers360_3 AS
     SELECT sha1(concat(contactID, lastModifiedDate)) AS pk
          , 'providers' AS provider
          , 3 AS sgroup
          , w.*
       FROM providersWork w
       JOIN (SELECT firstname
                  , lastname
                  , accountname
                  , count(*)
               FROM providersWork
           GROUP BY firstname
                  , lastname
                  , accountname
             HAVING count(*) > 1
            ) t
          ON w.firstname = t.firstname
        AND w.lastname = t.lastname
        AND w.accountname = t.accountname
      WHERE 1=1
        AND LastModifiedBy != 'DataSync'
;


DELETE
       FROM providersWork
      WHERE 1=1
        AND contactID IN (SELECT contactID
                             FROM providers360_3)
;

DELETE
       FROM providersWork USING providers360_3 t
      WHERE 1=1
        AND providersWork.firstname = t.firstname
        AND providersWork.lastname = t.lastname
        AND providersWork.accountname = t.accountname
;

/* Fourth Group: Most Recent Unique Firstname , Lastname , Account */
CREATE OR REPLACE TABLE providers360_4 AS
     SELECT sha1(concat(contactID, lastModifiedDate)) AS pk
          , 'providers' AS provider
          , 4 AS sgroup
          , w.*
       FROM providersWork w
       JOIN (SELECT max(contactid) AS selectedId
                  , firstname
                  , lastname
                  , accountname
               FROM providersWork
           GROUP BY firstname
                  , lastname
                  , accountname
            ) t
          ON w.contactID = t.selectedID
;


DELETE
       FROM providersWork
      WHERE 1=1
        AND contactID IN (SELECT contactID
                             FROM providers360_4)
;

DELETE
       FROM providersWork USING providers360_4 t
      WHERE 1=1
        AND providersWork.firstname = t.firstname
        AND providersWork.lastname = t.lastname
        AND providersWork.accountname = t.accountname
;

/* No records are left */
     SELECT *
       FROM providersWork
;