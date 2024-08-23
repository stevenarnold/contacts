/* Heuristics for identifying unique contacts within a contact file */
/* In this example , dart's data ( SANDBOX_SARNOLD.CONTACTS.dart360FLAT ) is used */
     SELECT count(*)
       FROM SANDBOX_SARNOLD.CONTACTS.dart360FLAT
;

/* Create workspace table */
/* ( Note name change from dart to dart from this point forward ) */
CREATE OR REPLACE TABLE dartWork AS
     SELECT FILENAME
          , CONTACTOWNER
          , CONTACTOWNERALIAS
          , CREATEDBY
          , CREATEDALIAS
          , LASTMODIFIEDBY
          , LASTMODIFIEDALIAS
          , MIDDLENAME 
          , SUFFIX 
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
       FROM SANDBOX_SARNOLD.CONTACTS.dart360FLAT
;

/* First Group: Email Cardinality */
CREATE OR REPLACE TABLE dart360_1 AS
     SELECT sha1(concat(contactID, lastModifiedDate)) AS pk
          , 'dart' AS provider
          , 1 AS sgroup
          , *
       FROM dartWork
      WHERE 1=1
        AND email IN (SELECT email
       FROM dartWork
    GROUP BY email
     HAVING count (*) = 1)
;

 DELETE
       FROM dartWork
      WHERE 1=1
        AND contactID IN (SELECT contactID
                             FROM dart360_1)
;

/* Second Group: Unique Firstname , Lastname , Account */
     CREATE OR REPLACE TABLE dart360_2 AS
     SELECT sha1(concat(contactID, lastModifiedDate)) AS pk
          , 'dart' AS provider
          , 2 AS sgroup
          , w.*
       FROM dartWork w
       JOIN (SELECT firstname
                  , lastname
                  , accountname
                  , count(*)
               FROM dartWork
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
       FROM dartWork
      WHERE 1=1
        AND contactID IN (SELECT contactID
                             FROM dart360_2)
;

/* Third Group: Unique Firstname , Lastname , Account not by DataSync */
     CREATE OR REPLACE TABLE dart360_3 AS
     SELECT sha1(concat(contactID, lastModifiedDate)) AS pk
          , 'dart' AS provider
          , 3 AS sgroup
          , w.*
       FROM dartWork w
       JOIN (SELECT firstname
                  , lastname
                  , accountname
                  , count(*)
               FROM dartWork
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
       FROM dartWork
      WHERE 1=1
        AND contactID IN (SELECT contactID
                             FROM dart360_3)
;

DELETE
       FROM dartWork USING dart360_3 t
      WHERE 1=1
        AND dartWork.firstname = t.firstname
        AND dartWork.lastname = t.lastname
        AND dartWork.accountname = t.accountname
;

/* Fourth Group: Most Recent Unique Firstname , Lastname , Account */
CREATE OR REPLACE TABLE dart360_4 AS
     SELECT sha1(concat(contactID, lastModifiedDate)) AS pk
          , 'dart' AS provider
          , 4 AS sgroup
          , w.*
       FROM dartWork w
       JOIN (SELECT max(contactid) AS selectedId
                  , firstname
                  , lastname
                  , accountname
               FROM dartWork
           GROUP BY firstname
                  , lastname
                  , accountname
            ) t
          ON w.contactID = t.selectedID
;


DELETE
       FROM dartWork
      WHERE 1=1
        AND contactID IN (SELECT contactID
                             FROM dart360_4)
;

DELETE
       FROM dartWork USING dart360_4 t
      WHERE 1=1
        AND dartWork.firstname = t.firstname
        AND dartWork.lastname = t.lastname
        AND dartWork.accountname = t.accountname
;

/* No records are left */
     SELECT *
       FROM dartWork
;

CREATE OR replace table dart360all AS
     SELECT *
       FROM dart360_1
      UNION ALL
     SELECT *
       FROM dart360_2
      UNION ALL
     SELECT *
       FROM dart360_3
      UNION ALL
     SELECT *
       FROM dart360_4
;

