/* Heuristics for identifying unique contacts within a contact file */
/* In this example , cms's data ( SANDBOX_SARNOLD.CONTACTS.cms360FLAT ) is used */
     SELECT count(*)
       FROM SANDBOX_SARNOLD.CONTACTS.cms360FLAT
;

/* Create workspace table */
/* ( Note name change from dart to cms from this point forward ) */
CREATE OR REPLACE TABLE cmsWork AS
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
          , '' AS ASST_PHONE
          , OWNERROLEDISPLAY
          , OWNERROLENAME
          , LASTACTIVITY
          , DESCRIPTION
          , LASTMODIFIEDDATE
          , CREATEDDATE
          , CONTACTID
          , REPORTSTO
          , NULL AS LASTSTAY_IN_TOUCHREQUESTDATE
          , NULL AS LASTSTAY_IN_TOUCHSAVEDATE
          , '' AS DATA_COMKEY
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
       FROM SANDBOX_SARNOLD.CONTACTS.cms360FLAT
;

/* First Group: Email Cardinality */
CREATE OR REPLACE TABLE cms360_1 AS
     SELECT sha1(concat(contactID, lastModifiedDate)) AS pk
          , 'cms' AS provider
          , 1 AS sgroup
          , *
       FROM cmsWork
      WHERE 1=1
        AND email IN (SELECT email
       FROM cmsWork
    GROUP BY email
     HAVING count (*) = 1)
;

 DELETE
       FROM cmsWork
      WHERE 1=1
        AND contactID IN (SELECT contactID
                             FROM cms360_1)
;

/* Second Group: Unique Firstname , Lastname , Account */
     CREATE OR REPLACE TABLE cms360_2 AS
     SELECT sha1(concat(contactID, lastModifiedDate)) AS pk
          , 'cms' AS provider
          , 2 AS sgroup
          , w.*
       FROM cmsWork w
       JOIN (SELECT firstname
                  , lastname
                  , accountname
                  , count(*)
               FROM cmsWork
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
       FROM cmsWork
      WHERE 1=1
        AND contactID IN (SELECT contactID
                             FROM cms360_2)
;

/* Third Group: Unique Firstname , Lastname , Account not by DataSync */
     CREATE OR REPLACE TABLE cms360_3 AS
     SELECT sha1(concat(contactID, lastModifiedDate)) AS pk
          , 'cms' AS provider
          , 3 AS sgroup
          , w.*
       FROM cmsWork w
       JOIN (SELECT firstname
                  , lastname
                  , accountname
                  , count(*)
               FROM cmsWork
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
       FROM cmsWork
      WHERE 1=1
        AND contactID IN (SELECT contactID
                             FROM cms360_3)
;

DELETE
       FROM cmsWork USING cms360_3 t
      WHERE 1=1
        AND cmsWork.firstname = t.firstname
        AND cmsWork.lastname = t.lastname
        AND cmsWork.accountname = t.accountname
;

/* Fourth Group: Most Recent Unique Firstname , Lastname , Account */
CREATE OR REPLACE TABLE cms360_4 AS
     SELECT sha1(concat(contactID, lastModifiedDate)) AS pk
          , 'cms' AS provider
          , 4 AS sgroup
          , w.*
       FROM cmsWork w
       JOIN (SELECT max(contactid) AS selectedId
                  , firstname
                  , lastname
                  , accountname
               FROM cmsWork
           GROUP BY firstname
                  , lastname
                  , accountname
            ) t
          ON w.contactID = t.selectedID
;


DELETE
       FROM cmsWork
      WHERE 1=1
        AND contactID IN (SELECT contactID
                             FROM cms360_4)
;

DELETE
       FROM cmsWork USING cms360_4 t
      WHERE 1=1
        AND cmsWork.firstname = t.firstname
        AND cmsWork.lastname = t.lastname
        AND cmsWork.accountname = t.accountname
;

/* No records are left */
     SELECT *
       FROM cmsWork
;

CREATE OR replace table cms360all AS
     SELECT *
       FROM cms360_1
      UNION ALL
     SELECT *
       FROM cms360_2
      UNION ALL
     SELECT *
       FROM cms360_3
      UNION ALL
     SELECT *
       FROM cms360_4
;

