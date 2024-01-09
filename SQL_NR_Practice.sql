insert into sap_note(dlvdate_E,dlvdate,tn_type,dlvno,noteno,item,ctype,id_acc,id_sub,id_dept,dramt,cramt,dlvno2,cusno,prdline,area,duedate,paycnd,stus,upddate,updtime,upduserid,HBKID,HKTID,trn,whno)
select
dbo.cdatetodate(x.dlvdate) as dlvdate_E,
x.dlvdate,
x.tn_type,
x.dlvno,
x.noteno,
x.item,
x.ctype,
x.id_acc,
x.id_sub,
x.id_dept,
x.dramt,
x.cramt,
x.dlvno2,
x.cusno,
x.prdline,
x.area,
x.duedate,
x.paycnd,
'' as stus,
'1130101' as upddate,
'1200' as updtime,
'12345' as upduserid,
x.HBKID, --1124增加託收銀行前四碼欄位
x.HKTID,  ----1124增加託收銀行後九碼欄位
'S3' as trn,
x.whno
from(
    select
	m.notedate as dlvdate,
	'N2票據' as tn_type,
    m.noteno as dlvno,
    m.noteno,
	d.item,
    '1.DR' as ctype,
    (case when d.prdline not in('9','X','E') and isnull(c.rela_yn,'N')='Y' THEN '1310000000'
		  when d.prdline in ('9','X','E') and isnull(c.rela_yn,'N')='Y' then '1310010000'
		  when d.prdline not in('9','X','E') and isnull(c.rela_yn,'N')='N' then '1410000000'
		  when d.prdline in ('9','X','E') and isnull(c.rela_yn,'N')='N' then '1410010000'
		  else '' end) 
		AS ID_ACC,--應收票據
	--case when isnull(c.rela_yn,'N')='Y' then c.id_sub else '' END   AS ID_SUB ,
	'' as ID_SUB,
    '' as id_dept,     
    sum(d.noteamt) as dramt,
    0 as cramt,
	m.bankno as dlvno2, 
	c.cusno_new AS CUSNO,
    '' as PRDLINE,
	l.cr_area as AREA, --一張票可能跨兩個額度區
	m.duedate as duedate,
	m.pre_cashdate as paycnd, -- sap 規劃日期 票據預計到期日 資金預測使用
	b.HBKID as HBKID,  -- 11/24 銀行帳號前四碼
	b.HKTID as HKTID, --11/24 銀行帳號後九碼
	m.whno
    from nrnoteds m ,nrnotedd d,ccm c, bank b,cpl l 
    where 1=1
	and m.noteno=d.noteno
	and d.cusno = c.cusno
	and c.parent_cusno=l.cusno and d.prdline=l.prdline
	and m.bankno = b.bankno
	and m.notedate>='1121101' and m.notedate<='1121130'
    and m.trn='N2'
    and isnull(m.stus,'') not like '%V%'
    --and m.noteno like 'C%'
    --and m.nrpayno<>'999'--排除非貨款
    group by m.noteno,m.notedate,m.org_noteno,m.duedate,d.item,m.pre_cashdate,c.rela_yn,m.bankno,c.cusno_new,m.whno,b.HBKID,b.HKTID,l.cr_area,
	(case when d.prdline not in('9','X','E') and isnull(c.rela_yn,'N')='Y' THEN '1310000000'
		  when d.prdline in ('9','X','E') and isnull(c.rela_yn,'N')='Y' then '1310010000'
		  when d.prdline not in('9','X','E') and isnull(c.rela_yn,'N')='N' then '1410000000'
		  when d.prdline in ('9','X','E') and isnull(c.rela_yn,'N')='N' then '1410010000'
		  else '' end)


    union all

    select
	m.notedate as dlvdate,
	'N2票據' as tn_type,
    m.noteno as dlvno,
	m.noteno,
    d.item,
    '2.CR' as ctype,
    case when isnull(c.rela_yn,'N')='Y' THEN '1330010000' else '1430010000' end   AS ID_ACC,--應收帳款溢付款
	'' as ID_SUB,
    '' as id_dept, --利潤中心
	0 as dramt,
    d.noteamt as cramt,
	'' as dlvno2,
    C.CUSNO_NEW AS cusno,
    d.prdline,
    l.AREA ,
	m.pre_cashdate as duedate,
	'' as paycnd,
	'' as HBKID,
	'' as HKTID,
	m.whno
    from nrnoteds m,nrnotedd d,ccm c,cpl l
    where 1=1
    and m.noteno=d.noteno
    and d.cusno=c.cusno
	and d.cusno = l.cusno and d.prdline = l.prdline
    and m.notedate>='1121101' and m.notedate<='1121130'
    and m.trn='N2'
    and isnull(m.stus,'') not like '%V%'
    --and m.noteno like 'C%'
    --and m.nrpayno<>'999'--排除非貨款	
)X
left join sap_note s on x.dlvno = s.dlvno
where 1=1
and isnull(s.dlvno,'') = ''
order by X.dlvdate,X.noteno,X.ctype