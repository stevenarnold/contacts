/* Heuristics for identifying unique contacts within a contact file */
/* In this example , fairway's data ( SANDBOX_SARNOLD.CONTACTS.fairway360FLAT ) is used */
     SELECT count(*)
       FROM SANDBOX_SARNOLD.CONTACTS.fairway360FLAT
;

/* Create workspace table */
/* ( Note name change from dart to fairway from this point forward ) */
CREATE OR REPLACE TABLE fairwayWork AS
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
       FROM SANDBOX_SARNOLD.CONTACTS.fairway360FLAT
;

/* First Group: Email Cardinality */
CREATE OR REPLACE TABLE fairway360_1 AS
     SELECT sha1(concat(contactID, lastModifiedDate)) AS pk
          , 'fairway' AS provider
          , 1 AS sgroup
          , *
       FROM fairwayWork
      WHERE 1=1
        AND email IN (SELECT email
       FROM fairwayWork
    GROUP BY email
     HAVING count (*) = 1)
;

 DELETE
       FROM fairwayWork
      WHERE 1=1
        AND contactID IN (SELECT contactID
                             FROM fairway360_1)
;

/* Second Group: Unique Firstname , Lastname , Account */
     CREATE OR REPLACE TABLE fairway360_2 AS
     SELECT sha1(concat(contactID, lastModifiedDate)) AS pk
          , 'fairway' AS provider
          , 2 AS sgroup
          , w.*
       FROM fairwayWork w
       JOIN (SELECT firstname
                  , lastname
                  , accountname
                  , count(*)
               FROM fairwayWork
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
       FROM fairwayWork
      WHERE 1=1
        AND contactID IN (SELECT contactID
                             FROM fairway360_2)
;

/* Third Group: Unique Firstname , Lastname , Account not by DataSync */
     CREATE OR REPLACE TABLE fairway360_3 AS
     SELECT sha1(concat(contactID, lastModifiedDate)) AS pk
          , 'fairway' AS provider
          , 3 AS sgroup
          , w.*
       FROM fairwayWork w
       JOIN (SELECT firstname
                  , lastname
                  , accountname
                  , count(*)
               FROM fairwayWork
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
       FROM fairwayWork
      WHERE 1=1
        AND contactID IN (SELECT contactID
                             FROM fairway360_3)
;

DELETE
       FROM fairwayWork USING fairway360_3 t
      WHERE 1=1
        AND fairwayWork.firstname = t.firstname
        AND fairwayWork.lastname = t.lastname
        AND fairwayWork.accountname = t.accountname
;

/* Fourth Group: Most Recent Unique Firstname , Lastname , Account */
CREATE OR REPLACE TABLE fairway360_4 AS
     SELECT sha1(concat(contactID, lastModifiedDate)) AS pk
          , 'fairway' AS provider
          , 4 AS sgroup
          , w.*
       FROM fairwayWork w
       JOIN (SELECT max(contactid) AS selectedId
                  , firstname
                  , lastname
                  , accountname
               FROM fairwayWork
           GROUP BY firstname
                  , lastname
                  , accountname
            ) t
          ON w.contactID = t.selectedID
;


DELETE
       FROM fairwayWork
      WHERE 1=1
        AND contactID IN (SELECT contactID
                             FROM fairway360_4)
;

DELETE
       FROM fairwayWork USING fairway360_4 t
      WHERE 1=1
        AND fairwayWork.firstname = t.firstname
        AND fairwayWork.lastname = t.lastname
        AND fairwayWork.accountname = t.accountname
;

/* No records are left */
     SELECT *
       FROM fairwayWork
;

CREATE OR replace table fairway360all AS
     SELECT *
       FROM fairway360_1
      UNION ALL
     SELECT *
       FROM fairway360_2
      UNION ALL
     SELECT *
       FROM fairway360_3
      UNION ALL
     SELECT *
       FROM fairway360_4
;

