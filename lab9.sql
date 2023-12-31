
grant 
  create sequence, 
  create cluster
to DEA;

alter database open;

grant create TABLESPACE to DEA;
grant alter TABLESPACE to DEA;
grant create synonym to DEA;
grant create public synonym to DEA;

grant create materialized view to DEA;
grant create view to DEA;
grant query rewrite to DEA;
-------------CREAE SEQUENCE------------
--3

create sequence S1
  increment by 10
  start with 1000
  nomaxvalue
  nominvalue
  nocycle
  nocache   --cache 20
  noorder;  --order (the chronology of values is not guaranteed)
  
  select s1.currval, s1.nextval from dual;
  
  drop sequence s1;
  
  --4
  
  create sequence S2
    increment by 10
    start with 10
    maxvalue 100
    nominvalue
    nocycle;
    
select s2.currval, s2.nextval from dual;
select s2.nextval from dual; -- ����� �� ������� ���� �������� (����� ��������� ��������� ���)

drop sequence s2;

--5
create sequence S3
  increment by -10
  start with 10
  maxvalue 20  --START WITH cannot be more than MAXVALUE
  minvalue -100
  nocycle
  order;
  
select S3.nextval from dual; -- ��������� ��������� ���

drop sequence S3;

--6
create sequence S4
  increment by 1
  start with 1
  maxvalue 10 --CYCLE must specify MAXVALUE
  cycle
  cache 5
  noorder;
  
select S4.nextval from dual;

drop sequence S4;

--check for existing sequences
--select * from user_sequences;
--7
select sequence_name, sequence_owner from sys.dba_sequences
    
---------tables--------------
--select * from user_tablespaces;

--8
create table T133
  (
   N1 NUMBER(20), 
   N2 NUMBER(20), 
   N3 NUMBER(20), 
   N4 NUMBER(20)
  ) storage(buffer_pool KEEP);
    
    
insert into T1 values (s1.nextval, s2.nextval, s3.nextval, s4.nextval);

select * from T1;

----------clusters------------
--9-12
create cluster ABC        --hash-type
  (
    X NUMBER (10),
    V VARCHAR2 (12)
  ) hashkeys 200;    --specifies and limits the number of unique hash values that can be generated by the hash function used by the cluster. 

  
  
create table A
  (
    XA NUMBER (10),
    VA VARCHAR2 (12),
    AA int
  ) cluster ABC (XA, VA);
  
create table B
  (
    XB NUMBER (10),
    VB VARCHAR2 (12),
    BB int
  ) cluster ABC (XB, VB);
  
create table C
  (
    XC NUMBER (10),
    VC VARCHAR2 (12),
    CC int
  ) cluster ABC (XC, VC);
  
--find created tables and clusters in dictionaries Oracle
--dba_clusters
--dba_tables

--13
select cluster_name, owner, tablespace_name, cluster_type, cache from dba_clusters;

select * from dba_tables where table_name = 'A' OR table_name = 'B' OR table_name = 'C';

select * from user_clusters;
select * from user_tables;

---------------synonym------------------------------
--14-15
create synonym SYN_C for C;

select * from SYN_C;

drop synonym SYN_C;

-------------public synonym-------------------------
create public synonym PUBL_SYN_c for B;

select * from PUBL_SYN_B;

drop synonym PUBL_SYN_B;

select * from user_synonyms;
--------------------------------------------------------------------------------
--16
create table AA 
  (
    X number (10),
    V varchar2 (12),
    constraint X_PK primary key (X)
  );
  
insert into AA (X, V) values (1, 'one');
insert into AA (X, V) values (2, 'two');
insert into AA (X, V) values (3, 'three');
insert into AA (X, V) values (4, 'four');
insert into AA (X, V) values (5, 'five');

select * from AA;

create table BB
  (
    XX NUMBER (10),
    VV VARCHAR2 (12),
    constraint XX_PK foreign key (XX) references AA(X)
  );
  
insert into BB (XX, VV) values (1, 'odin');
insert into BB (XX, VV) values (2, 'dva');
insert into BB (XX, VV) values (3, 'tri');
insert into BB (XX, VV) values (4, 'chetyre');
insert into BB (XX, VV) values (5, 'pyat');

select * from BB

create view V1
as
  select AA.X, AA.V, BB.VV
    from AA inner join BB on AA.X = BB.XX;
    
select * from V1;

--17
create materialized view MV
  build immediate         --create view in moment of operator's processing
  refresh complete        --fast / copmlete / force(default)
  as select AA.X, AA.V, BB.VV
  from AA
  inner join BB on AA.X = BB.XX;
  
alter materialized view MV
    refresh complete on demand
    next sysdate + numtodsinterval (2, 'MINUTE');
  
select * from MV;

drop materialized view;

--18
--as sys dba
GRANT CREATE DATABASE LINK TO DEA;



CREATE DATABASE LINK DEMID3
   CONNECT TO C##DEA
   IDENTIFIED BY Tt050403
   USING 'demid3';

select * from tab@demid3;


--19. select, insert, update, delete, function, procedure with objects of remote server

--create SYSTEM table


select * from T1@demid3;
--drop table test_dblink

insert into T1@demid3 values(1, 'one');

update T1@demid3 set str = 'dva' where num = 1;

delete from T1@demid3 where num = 1;

CREATE PROCEDURE get_rows_by_str(p_str IN nvarchar2) IS
numb int;
stri nvarchar2(50);
BEGIN
  SELECT num, str
  INTO numb, stri
  FROM T1@demid3
  WHERE str = p_str;
END;

begin
get_rows_by_str('one');
end;

drop procedure get_rows_by_str
