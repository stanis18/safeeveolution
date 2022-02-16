use std::{fs::File, io::BufReader, path::Path};
use serde_json::{Map, Value as JsonValue};
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Debug,Clone)]
#[serde(rename_all = "camelCase")]
struct SpecArtifact {
    nodes: (JsonValue, JsonValue),
}

#[derive(Debug,Clone)]
pub struct Specification {
    pub contract_name: String,
    pub invariant: String,
    pub variables: Vec<VariableDeclaration>,
    pub functions: Vec<FunctionSpecification>,
}

#[derive(Debug,Clone)]
pub struct FunctionSpecification {
    pub spec: String,
    pub signature: FunctionSignature,
    
}

#[derive(PartialEq,Debug,Clone)]
pub struct FunctionSignature {
    pub kind: String,
    pub name: String,
    pub ins: Vec<VariableDeclaration>,
    pub outs: Vec<VariableDeclaration>,
    pub visibility : String,
    pub state_mutability : String,
}

#[derive(PartialEq, Debug,Clone)]
pub struct VariableDeclaration {
    pub visibility: String,
    pub typ : String,
    pub name : String,
    pub storage_location : String,
}

#[derive(Serialize, Deserialize, Debug,Clone)]
struct SolcArtifact {
    nodes: Vec<JsonValue>,
}

#[derive(Debug,Clone)]
pub struct Implementation {
    pub contract_name: String,
    pub variables: Vec<VariableDeclaration>, 
    pub functions: Vec<FunctionImplementation>,
    pub contract_definition: Src,
    pub contracts_inherited : Vec<Implementation>
 }

 #[derive(Debug, Clone)]
 pub struct FunctionImplementation {
    pub signature: FunctionSignature,
    pub src: Src,
    pub body: Src,
}

#[derive(Debug,Clone)]
pub struct Src {
    pub offset: u64, // in bytes
    pub length: u64, // in bytes
    pub source_unit: u64, // identifier
}


pub fn parse_specification(spec_path : &Path) -> Result<Specification, String> {
    let file = File::open(spec_path).map_err( |_| {"Error opening json spec".to_owned()} )?;
    let reader = BufReader::new(file);
    
    let u : SpecArtifact = serde_json::from_reader(reader).map_err( |_| {"Error parsing json spec".to_owned()} )?;
    parse_pragma(&u.nodes.0)?;
    let spec = parse_spec_contract(&u.nodes.1)?;
    Ok(spec)
}

fn parse_pragma(pragma : &JsonValue) -> Result<(), String> {
    if let serde_json::Value::Object(map) = pragma {
        if let Some(serde_json::Value::String(s)) = map.get("nodeType") {
            if s == "PragmaDirective" {
                return Ok(())
            }
        }
    };
    Err("Expecting pragma directive".to_owned())
}

fn parse_spec_contract(contract : &JsonValue) -> Result<Specification, String> {
    let contract_elements = parse_node(contract, "ContractDefinition")?;

    let invariant = if let Some(serde_json::Value::String(invariant)) = contract_elements.get("documentation") {
        parse_invariant(invariant).unwrap()
    } else {
        "".to_string()
    };
    
    let (variables, functions) = if let Some(serde_json::Value::Array(values)) = contract_elements.get("nodes") {
        (parse_variables(&values)?,parse_function_specifications(&values)?)
    } else {
        return Err("Missing definitions".to_owned());
    };
    
    Ok(Specification {
        contract_name: contract.get("name").unwrap().to_string(),
        invariant,
        variables,
        functions,
    })
}

fn parse_invariant(string: &str) -> Result<String,String> {
   
    for line in string.lines() {
        let line_without_whitespace: String = line.split_whitespace().collect();
        if !&line_without_whitespace.starts_with("@noticeinvariant") {
            return Err("Contract comment must only contain @notice invariant lines".to_owned());
        }
    }
    Ok(string.to_owned())
}

fn parse_variables(values : &Vec<JsonValue>) -> Result<Vec<VariableDeclaration>,String> {
    let mut var_decls = Vec::new();
    for value in values {
        if let Ok(var_decl) = parse_variable_declaration(value) {
            var_decls.push(var_decl);
        }
    }
    Ok(var_decls)
}

fn parse_function_specifications(values : &Vec<JsonValue>) -> Result<Vec<FunctionSpecification>,String> {
    let mut func_specs = Vec::new();
    for value in values {
        if let Ok(func_spec) = parse_function_specification(value) {
            func_specs.push(func_spec);
        }
    }
    Ok(func_specs)
}

fn parse_node<'a>(node_object : &'a JsonValue, typ : &str) -> Result<&'a Map<String, JsonValue>, String> {
    if let serde_json::Value::Object(map) = node_object {
        if let Some(serde_json::Value::String(s)) = map.get("nodeType") {
            if s == typ {
                return Ok(map);
            } else {
                return Err(format!("Expecting {} found {} ", typ, s));
            }
        }
    };
    Err(format!("Expecting {} node", typ))
}

fn parse_variable_declaration(var_decl : &JsonValue) -> Result<VariableDeclaration,String> {
    let var_decl = parse_node(var_decl, "VariableDeclaration")?;
    let type_string = var_decl.get("typeDescriptions").unwrap().as_object().unwrap().get("typeString").unwrap().as_str().unwrap();
    Ok(VariableDeclaration {
        storage_location : var_decl.get("storageLocation").unwrap().as_str().unwrap().to_string(),
        visibility: var_decl.get("visibility").unwrap().as_str().unwrap().to_string(),
        name: var_decl.get("name").unwrap().as_str().unwrap().to_string(),
        typ: type_string.to_string(),
    })
}

fn parse_function_specification(func_decl: &JsonValue) -> Result<FunctionSpecification,String> {
    let func = parse_node(func_decl, "FunctionDefinition")?;
    let signature = parse_function_signature(func)?;
    let func_doc = func.get("documentation").unwrap().as_str().unwrap_or("").to_string();
    
    Ok(FunctionSpecification {
        spec: parse_function_postconditions(&func_doc)?,
        signature,
    })
}

fn parse_function_postconditions(string: &str) -> Result<String, String> {
    for line in string.lines() {
        let line_without_whitespace: String = line.split_whitespace().collect();
        if !&line_without_whitespace.starts_with("@noticepostcondition") {
            return Err("Function comment must only contain @notice postcondition lines".to_owned());
        }
    }
    Ok(string.to_owned())
}

fn parse_function_signature(func_decl: &Map<String,JsonValue>) -> Result<FunctionSignature,String> {
    let mut ins = Vec::new();
    let in_pars = func_decl.get("parameters").unwrap().as_object().unwrap().get("parameters").unwrap().as_array().unwrap();
    for in_par in in_pars {
        if let Ok(var_decl) = parse_variable_declaration(in_par) {
            ins.push(var_decl);
        } else {
            return Err("Unable to parse in par".to_owned());
        }
    }

    let mut outs = Vec::new();
    let out_pars = func_decl.get("returnParameters").unwrap().as_object().unwrap().get("parameters").unwrap().as_array().unwrap();
    for out_par in out_pars {
        if let Ok(var_decl) = parse_variable_declaration(out_par) {
            outs.push(var_decl);
        } else {
            return Err("Unable to parse out par".to_owned());
        }
    }

    Ok(FunctionSignature {
        kind : func_decl.get("kind").unwrap().as_str().unwrap().to_string(), 
        name: func_decl.get("name").unwrap().as_str().unwrap().to_string(),
        ins,
        outs,
        visibility: func_decl.get("visibility").unwrap().as_str().unwrap().to_string(),
        state_mutability: func_decl.get("stateMutability").unwrap().as_str().unwrap().to_string(),
    })
}

pub fn parse_implementation(impl_path : &Path) -> Result<Implementation,String> {

    let file = File::open(Path::new(&impl_path)).map_err( |_| {"Error opening json impl".to_owned()} )?;
    let reader = BufReader::new(file);

    let u : SolcArtifact = serde_json::from_reader(reader).map_err( |_| {"Error parsing json impl".to_owned()} )?;
    
    parse_pragma(&u.nodes[0])?;

    let imp = parse_impl_contract(&u.nodes)?;

    Ok(imp)
}


fn parse_contracts_inherited(values : &Vec<JsonValue>) -> Result<Vec<Implementation>,String> {
    let mut contr_decls = Vec::new();
    for value in values {
        if value.get("nodeType").unwrap().as_str().unwrap().to_string() == "ImportDirective" {
            
           let absolute_path = value.get("absolutePath").unwrap().as_str().unwrap().to_string();

           let impl_json_path = format!("{}_json.ast", 
                Path::new(Path::new(&absolute_path).strip_prefix("/sources").unwrap())
                    .file_name().unwrap().to_str().unwrap());
           
           let path = Path::new("contracts/input");

           if let Ok(var_decl) = parse_implementation(&path.join(&impl_json_path).as_path()) {
                contr_decls.push(var_decl);
            }
        }
    }
    Ok(contr_decls)
}

fn parse_impl_contract(contract_list : &Vec<JsonValue>) -> Result<Implementation, String> {

    let contract = &contract_list[contract_list.len() -1];

    let contract_elements = parse_node(&contract, "ContractDefinition")?;

    let src_info : Vec<&str> = contract.get("src").unwrap().as_str().unwrap().split(":").collect();

    if !contract_elements.get("documentation").unwrap().is_null() {
        return Err("Contract shouldn't have a comment".to_owned());
    };

    let contracts_inh = parse_contracts_inherited(&contract_list).unwrap();

    let (variables, functions) = if let Some(serde_json::Value::Array(values)) = contract_elements.get("nodes") {
        (parse_variables(&values)?,parse_function_implementations(&values)?)
    } else {
        return Err("Missing definitions".to_owned());
    };
    
    Ok(Implementation {
        contract_name: contract.get("name").unwrap().as_str().unwrap().to_string(),
        variables,
        functions,
        contracts_inherited : contracts_inh,
        contract_definition: Src {
            offset: src_info[0].parse().unwrap(),
            length: src_info[1].parse().unwrap(),
            source_unit: src_info[2].parse().unwrap(),
        },
    })
}

fn parse_function_implementations(values : &Vec<JsonValue>) -> Result<Vec<FunctionImplementation>,String> {
    let mut func_specs = Vec::new();
    for value in values {
        if let Ok(func_spec) = parse_function_implementation(value) {
            func_specs.push(func_spec);
        }
    }
    Ok(func_specs)
}

fn parse_function_body(func: &Map<String,JsonValue>) { 

    let src_info_body_statements : &Vec<JsonValue> = func.get("body").unwrap().as_object().unwrap().get("statements")
                                                    .unwrap().as_array().unwrap();
    
    let mut func_body : Vec<Src> = Vec::new();                                                    
    for value in src_info_body_statements {
        
        let t : Vec<&str> = value.as_object().unwrap().get("src").unwrap().as_str().unwrap().split(":").collect();
        
        let s : Src = Src{ offset: t[0].parse().unwrap(),
            length: t[1].parse().unwrap(),
            source_unit: t[2].parse().unwrap(), };
            
            func_body.push(s);
    }
}

fn parse_function_implementation(func_decl: &JsonValue) -> Result<FunctionImplementation,String> {
    let func = parse_node(func_decl, "FunctionDefinition")?;
    let signature = parse_function_signature(func)?;
    if !func.get("documentation").unwrap().is_null() {
        return Err("Function shouldn't have comment".to_owned())
    }

    let src_info : Vec<&str> = func.get("src").unwrap().as_str().unwrap().split(":").collect();

    let src_function_body : Vec<&str> = func.get("body").unwrap().as_object().unwrap().get("src")
                                    .unwrap().as_str().unwrap().split(":").collect();
    
    Ok(FunctionImplementation{
        signature,
        src: Src {
            offset: src_info[0].parse().unwrap(),
            length: src_info[1].parse().unwrap(),
            source_unit: src_info[2].parse().unwrap(),
        }, 
        body: Src {
            offset: src_function_body[0].parse().unwrap(),
            length: src_function_body[1].parse().unwrap(),
            source_unit: src_function_body[2].parse().unwrap(),
        }
    })

}

