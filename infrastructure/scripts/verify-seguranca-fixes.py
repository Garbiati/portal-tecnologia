#!/usr/bin/env python3
"""Verificação AO VIVO dos fixes do pentest (F1-F7) contra prod: provisiona usuários de papel único
(regulacao escopado a um cliente, gestor a uma unidade), loga como eles e confirma 403/PII-nula/escopo.
Limpa os usuários no fim. NÃO echoa segredo/PII."""
import os, json, subprocess, urllib.request, urllib.error, urllib.parse
import e2e_common as e

KC = e.KC
BOOT = subprocess.run(["gcloud","secrets","versions","access","latest","--secret=portal-identity-admin-password"],
                      capture_output=True, text=True).stdout.strip()
ATOK = json.load(urllib.request.urlopen(urllib.request.Request(
    f"{KC}/realms/master/protocol/openid-connect/token", method="POST",
    data=urllib.parse.urlencode({"client_id":"admin-cli","username":"admin","password":BOOT,"grant_type":"password"}).encode())))["access_token"]

def kc(method, path, body=None):
    r = urllib.request.Request(f"{KC}/admin/realms/portal{path}", method=method,
        headers={"Authorization":f"Bearer {ATOK}","Content-Type":"application/json"},
        data=json.dumps(body).encode() if body is not None else None)
    try:
        with urllib.request.urlopen(r) as x: t=x.read().decode(); return x.status,(json.loads(t) if t else None),x.headers
    except urllib.error.HTTPError as ex: return ex.code, ex.read().decode(), ex.headers

CID = kc("GET","/clients?clientId=doctor-hub-api")[1][0]["id"]
def role(name): return kc("GET",f"/clients/{CID}/roles/{name}")[1]

def provision(username, papel, cliente_id=None, unidade=None):
    attrs={"cpf":[e.cpf_valido()],"telefone":["11988887777"]}
    if cliente_id: attrs["clienteId"]=[cliente_id]
    if unidade: attrs["unidade"]=[unidade]
    st,_,h = kc("POST","/users",{"username":username,"enabled":True,"emailVerified":True,
        "firstName":"Sec","lastName":"Test","email":f"{username}@sec.local","attributes":attrs})
    uid = h["Location"].split("/")[-1] if st==201 else kc("GET",f"/users?username={username}")[1][0]["id"]
    kc("PUT",f"/users/{uid}/reset-password",{"type":"password","value":"Sec!Test123","temporary":False})
    r=role(papel); kc("POST",f"/users/{uid}/role-mappings/clients/{CID}",[{"id":r["id"],"name":papel}])
    return uid

def como(username):
    os.environ["E2E_ADMIN_USER"]=username; os.environ["E2E_ADMIN_PASS"]="Sec!Test123"
    os.environ["KC_REDIRECT"]="https://doctorhub.app.br/app"
    return e.login_token()

print("── setup: cliente + doctor reais (via admin all-roles) ──")
os.environ.pop("E2E_ADMIN_USER", None); os.environ.pop("E2E_ADMIN_PASS", None)  # usa .e2e-env do e2e-homolog
tok_adm = e.login_token()
clientes = e.api("GET","/clientes",tok_adm); cid0 = clientes[0]["id"]; csig0=clientes[0]["sigla"]
docs = e.api("GET","/doctors",tok_adm); did0 = docs[0]["id"]
e.check(docs[0].get("cpf"), "F1+ admin/demandas VÊ CPF (VeTudo)")   # positivo

reg = provision("sec-reg", "regulacao", cliente_id=cid0)
ges = provision("sec-ges", "gestor", unidade="U-ALPHA")
try:
    print(f"── como REGULAÇÃO (cliente {csig0}) ──")
    treg = como("sec-reg")
    docs_r = e.api("GET","/doctors",treg)
    e.check(isinstance(docs_r,list) and all(d.get("cpf") is None for d in docs_r[:20]), "F1 regulacao → CPF NULO em /doctors")
    r = e.api("POST",f"/doctors/{did0}/indisponibilidades",treg,{"inicio":"2026-07-10","fim":"2026-07-11","motivo":"x"})
    e.check(isinstance(r,dict) and r.get("_status")==403, "F2 regulacao POST indisponibilidade → 403")
    r = e.api("GET","/auditoria",treg); e.check(isinstance(r,dict) and r.get("_status")==403, "F4/F6 regulacao GET auditoria → 403")
    r = e.api("POST","/auditoria",treg,{"acao":"x","alvo":"y"}); e.check(isinstance(r,dict) and r.get("_status")==403, "F6 regulacao POST auditoria → 403")
    esc = e.api("GET","/escalas",treg)
    e.check(isinstance(esc,list) and all(x.get("clienteId") in (cid0,None) for x in esc), "F4 regulacao /escalas → só do seu cliente")
    r = e.api("GET","/tenants",treg); e.check(isinstance(r,dict) and r.get("_status")==403, "baseline regulacao GET tenants → 403 (super-admin)")

    print("── como GESTOR (unidade U-ALPHA) ──")
    tges = como("sec-ges")
    r = e.api("POST","/agendamentos",tges,{"vagaId":"v1","pacienteIniciais":"M S","unidade":"U-BETA"})
    e.check(isinstance(r,dict) and r.get("_status")==403, "F3 gestor assume vaga de OUTRA unidade → 403")

    print("── F7 rate-limit (anônimo) ──")
    RL="https://api.portaltecnologia.app.br/api/inscricoes"
    def _post(i):
        try: return e.api_raw("POST",RL,None,{"email":f"rl{i}@t.local","origem":"landing-medico"})[0]
        except Exception as ex: return getattr(ex,"code",0)   # 429 pode vir como exceção
    codes=[_post(i) for i in range(7)]
    e.check(429 in codes, f"F7 /inscricoes rate-limit → 429 após 5 (códigos: {codes})")
finally:
    kc("DELETE",f"/users/{reg}"); kc("DELETE",f"/users/{ges}")
    print("  ✓ usuários de teste removidos")
e.report("PENTEST — verificação dos fixes")
