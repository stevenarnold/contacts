/* Heuristics for identifying unique contacts within a contact file */
/* In this example , prmg's data ( SANDBOX_SARNOLD.CONTACTS.prmg360FLAT ) is used */
     SELECT count(*)
       FROM SANDBOX_SARNOLD.CONTACTS.prmg360FLAT
;

/* Create workspace table */
/* ( Note name change from dart to prmg from this point forward ) */
CREATE OR REPLACE TABLE prmgWork AS
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
       FROM SANDBOX_SARNOLD.CONTACTS.prmg360FLAT
;

/* First Group: Email Cardinality */
CREATE OR REPLACE TABLE prmg360_1 AS
     SELECT sha1(concat(contactID, lastModifiedDate)) AS pk
          , 'prmg' AS provider
          , 1 AS sgroup
          , *
       FROM prmgWork
      WHERE 1=1
        AND email IN (SELECT email
       FROM prmgWork
    GROUP BY email
     HAVING count (*) = 1)
;

 DELETE
       FROM prmgWork
      WHERE 1=1
        AND contactID IN (SELECT contactID
                             FROM prmg360_1)
;

/* Second Group: Unique Firstname , Lastname , Account */
     CREATE OR REPLACE TABLE prmg360_2 AS
     SELECT sha1(concat(contactID, lastModifiedDate)) AS pk
          , 'prmg' AS provider
          , 2 AS sgroup
          , w.*
       FROM prmgWork w
       JOIN (SELECT firstname
                  , lastname
                  , accountname
                  , count(*)
               FROM prmgWork
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
       FROM prmgWork
      WHERE 1=1
        AND contactID IN (SELECT contactID
                             FROM prmg360_2)
;

/* Third Group: Unique Firstname , Lastname , Account not by DataSync */
     CREATE OR REPLACE TABLE prmg360_3 AS
     SELECT sha1(concat(contactID, lastModifiedDate)) AS pk
          , 'prmg' AS provider
          , 3 AS sgroup
          , w.*
       FROM prmgWork w
       JOIN (SELECT firstname
                  , lastname
                  , accountname
                  , count(*)
               FROM prmgWork
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
       FROM prmgWork
      WHERE 1=1
        AND contactID IN (SELECT contactID
                             FROM prmg360_3)
;

DELETE
       FROM prmgWork USING prmg360_3 t
      WHERE 1=1
        AND prmgWork.firstname = t.firstname
        AND prmgWork.lastname = t.lastname
        AND prmgWork.accountname = t.accountname
;

/* Fourth Group: Most Recent Unique Firstname , Lastname , Account */
CREATE OR REPLACE TABLE prmg360_4 AS
     SELECT sha1(concat(contactID, lastModifiedDate)) AS pk
          , 'prmg' AS provider
          , 4 AS sgroup
          , w.*
       FROM prmgWork w
       JOIN (SELECT max(contactid) AS selectedId
                  , firstname
                  , lastname
                  , accountname
               FROM prmgWork
           GROUP BY firstname
                  , lastname
                  , accountname
            ) t
          ON w.contactID = t.selectedID
;


DELETE
       FROM prmgWork
      WHERE 1=1
        AND contactID IN (SELECT contactID
                             FROM prmg360_4)
;

DELETE
       FROM prmgWork USING prmg360_4 t
      WHERE 1=1
        AND prmgWork.firstname = t.firstname
        AND prmgWork.lastname = t.lastname
        AND prmgWork.accountname = t.accountname
;

/* No records are left */
     SELECT *
       FROM prmgWork
;

CREATE OR replace table prmg360all AS
     SELECT *
       FROM prmg360_1
      UNION ALL
     SELECT *
       FROM prmg360_2
      UNION ALL
     SELECT *
       FROM prmg360_3
      UNION ALL
     SELECT *
       FROM prmg360_4
;

