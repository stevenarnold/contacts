/* Heuristics for identifying unique contacts within a contact file */
/* In this example , vc's data ( SANDBOX_SARNOLD.CONTACTS.vc360FLAT ) is used */
     SELECT count(*)
       FROM SANDBOX_SARNOLD.CONTACTS.vc360FLAT
;

/* Create workspace table */
/* ( Note name change from dart to vc from this point forward ) */
CREATE OR REPLACE TABLE vcWork AS
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
       FROM SANDBOX_SARNOLD.CONTACTS.vc360FLAT
;

/* First Group: Email Cardinality */
CREATE OR REPLACE TABLE vc360_1 AS
     SELECT sha1(concat(contactID, lastModifiedDate)) AS pk
          , 'vc' AS provider
          , 1 AS sgroup
          , *
       FROM vcWork
      WHERE 1=1
        AND email IN (SELECT email
       FROM vcWork
    GROUP BY email
     HAVING count (*) = 1)
;

 DELETE
       FROM vcWork
      WHERE 1=1
        AND contactID IN (SELECT contactID
                             FROM vc360_1)
;

/* Second Group: Unique Firstname , Lastname , Account */
     CREATE OR REPLACE TABLE vc360_2 AS
     SELECT sha1(concat(contactID, lastModifiedDate)) AS pk
          , 'vc' AS provider
          , 2 AS sgroup
          , w.*
       FROM vcWork w
       JOIN (SELECT firstname
                  , lastname
                  , accountname
                  , count(*)
               FROM vcWork
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
       FROM vcWork
      WHERE 1=1
        AND contactID IN (SELECT contactID
                             FROM vc360_2)
;

/* Third Group: Unique Firstname , Lastname , Account not by DataSync */
     CREATE OR REPLACE TABLE vc360_3 AS
     SELECT sha1(concat(contactID, lastModifiedDate)) AS pk
          , 'vc' AS provider
          , 3 AS sgroup
          , w.*
       FROM vcWork w
       JOIN (SELECT firstname
                  , lastname
                  , accountname
                  , count(*)
               FROM vcWork
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
       FROM vcWork
      WHERE 1=1
        AND contactID IN (SELECT contactID
                             FROM vc360_3)
;

DELETE
       FROM vcWork USING vc360_3 t
      WHERE 1=1
        AND vcWork.firstname = t.firstname
        AND vcWork.lastname = t.lastname
        AND vcWork.accountname = t.accountname
;

/* Fourth Group: Most Recent Unique Firstname , Lastname , Account */
CREATE OR REPLACE TABLE vc360_4 AS
     SELECT sha1(concat(contactID, lastModifiedDate)) AS pk
          , 'vc' AS provider
          , 4 AS sgroup
          , w.*
       FROM vcWork w
       JOIN (SELECT max(contactid) AS selectedId
                  , firstname
                  , lastname
                  , accountname
               FROM vcWork
           GROUP BY firstname
                  , lastname
                  , accountname
            ) t
          ON w.contactID = t.selectedID
;


DELETE
       FROM vcWork
      WHERE 1=1
        AND contactID IN (SELECT contactID
                             FROM vc360_4)
;

DELETE
       FROM vcWork USING vc360_4 t
      WHERE 1=1
        AND vcWork.firstname = t.firstname
        AND vcWork.lastname = t.lastname
        AND vcWork.accountname = t.accountname
;

/* No records are left */
     SELECT *
       FROM vcWork
;

CREATE OR replace table vc360all AS
     SELECT *
       FROM vc360_1
      UNION ALL
     SELECT *
       FROM vc360_2
      UNION ALL
     SELECT *
       FROM vc360_3
      UNION ALL
     SELECT *
       FROM vc360_4
;

