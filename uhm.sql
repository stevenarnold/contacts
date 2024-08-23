/* Heuristics for identifying unique contacts within a contact file */
/* In this example , uhm's data ( SANDBOX_SARNOLD.CONTACTS.uhm360FLAT ) is used */
     SELECT count(*)
       FROM SANDBOX_SARNOLD.CONTACTS.uhm360FLAT
;

/* Create workspace table */
/* ( Note name change from dart to uhm from this point forward ) */
CREATE OR REPLACE TABLE uhmWork AS
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
       FROM SANDBOX_SARNOLD.CONTACTS.uhm360FLAT
;

/* First Group: Email Cardinality */
CREATE OR REPLACE TABLE uhm360_1 AS
     SELECT sha1(concat(contactID, lastModifiedDate)) AS pk
          , 'uhm' AS provider
          , 1 AS sgroup
          , *
       FROM uhmWork
      WHERE 1=1
        AND email IN (SELECT email
       FROM uhmWork
    GROUP BY email
     HAVING count (*) = 1)
;

 DELETE
       FROM uhmWork
      WHERE 1=1
        AND contactID IN (SELECT contactID
                             FROM uhm360_1)
;

/* Second Group: Unique Firstname , Lastname , Account */
     CREATE OR REPLACE TABLE uhm360_2 AS
     SELECT sha1(concat(contactID, lastModifiedDate)) AS pk
          , 'uhm' AS provider
          , 2 AS sgroup
          , w.*
       FROM uhmWork w
       JOIN (SELECT firstname
                  , lastname
                  , accountname
                  , count(*)
               FROM uhmWork
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
       FROM uhmWork
      WHERE 1=1
        AND contactID IN (SELECT contactID
                             FROM uhm360_2)
;

/* Third Group: Unique Firstname , Lastname , Account not by DataSync */
     CREATE OR REPLACE TABLE uhm360_3 AS
     SELECT sha1(concat(contactID, lastModifiedDate)) AS pk
          , 'uhm' AS provider
          , 3 AS sgroup
          , w.*
       FROM uhmWork w
       JOIN (SELECT firstname
                  , lastname
                  , accountname
                  , count(*)
               FROM uhmWork
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
       FROM uhmWork
      WHERE 1=1
        AND contactID IN (SELECT contactID
                             FROM uhm360_3)
;

DELETE
       FROM uhmWork USING uhm360_3 t
      WHERE 1=1
        AND uhmWork.firstname = t.firstname
        AND uhmWork.lastname = t.lastname
        AND uhmWork.accountname = t.accountname
;

/* Fourth Group: Most Recent Unique Firstname , Lastname , Account */
CREATE OR REPLACE TABLE uhm360_4 AS
     SELECT sha1(concat(contactID, lastModifiedDate)) AS pk
          , 'uhm' AS provider
          , 4 AS sgroup
          , w.*
       FROM uhmWork w
       JOIN (SELECT max(contactid) AS selectedId
                  , firstname
                  , lastname
                  , accountname
               FROM uhmWork
           GROUP BY firstname
                  , lastname
                  , accountname
            ) t
          ON w.contactID = t.selectedID
;


DELETE
       FROM uhmWork
      WHERE 1=1
        AND contactID IN (SELECT contactID
                             FROM uhm360_4)
;

DELETE
       FROM uhmWork USING uhm360_4 t
      WHERE 1=1
        AND uhmWork.firstname = t.firstname
        AND uhmWork.lastname = t.lastname
        AND uhmWork.accountname = t.accountname
;

/* No records are left */
     SELECT *
       FROM uhmWork
;

CREATE OR replace table uhm360all AS
     SELECT *
       FROM uhm360_1
      UNION ALL
     SELECT *
       FROM uhm360_2
      UNION ALL
     SELECT *
       FROM uhm360_3
      UNION ALL
     SELECT *
       FROM uhm360_4
;

