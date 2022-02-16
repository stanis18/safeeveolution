use crate::parser::{Implementation,VariableDeclaration};
use std::fs::File;
use std::convert::TryInto;
use std::str;
use std::{path::Path};
use std::io::{self, prelude::*, SeekFrom, Read};
use crate::util::{write_file};

pub fn config_proxy (spec: &Implementation, impl_path: &Path){
    let mut file_implementation =
        File::open("contracts/proxy.sol")
            .unwrap();
        let mut data_implementation = String::new();
            file_implementation
                .read_to_string(&mut data_implementation)
                .unwrap();    
 
        data_implementation = data_implementation
                            .replace("/*constructor initialization */", &get_constructor_body(&spec, &impl_path).unwrap())
                            .replace("/* constructor parameters */", &get_constructor_paramts(&spec).unwrap())
                            .replace("/* variables */", &get_variables_proxy(&spec).unwrap())
                            .replace("/* functions */", &get_functions_proxy(&spec).unwrap());

                            write_file(&data_implementation.to_string(), &"implementedproxy.sol".to_string());
}

pub fn get_constructor_body(spec: &Implementation, impl_path: &Path) -> Result <String, ()> {

    let mut impl_file = File::open(&impl_path)
    .unwrap();

    for i in 0..spec.functions.len() {
        if &spec.functions[i].signature.kind == "constructor" {

            let body_length: usize = spec.functions[i].body.length.try_into().unwrap();
            let mut buf = vec![0; body_length];

            impl_file.seek(SeekFrom::Start(spec.functions[i].body.offset));
            impl_file.read_exact(buf.as_mut_slice()).unwrap();

            let body = str::from_utf8(buf.as_mut_slice()).unwrap();

            let mut chars_constructor_body = body.chars();
            chars_constructor_body.next();
            chars_constructor_body.next_back();

            let constructor_body: String = chars_constructor_body.collect();

            return Ok(constructor_body);
        }
    }    
    Ok("".to_owned())
}

pub fn get_constructor_paramts(spec: &Implementation) -> Result <String, ()> {
    for i in 0..spec.functions.len() {
        if &spec.functions[i].signature.kind == "constructor" {
            if &spec.functions[i].signature.ins.len() > &0 {
                return Ok(format!(",{}", get_parameters_type_name_paramts(&spec.functions[i].signature.ins) ));
            }
        }
    }
    Ok("".to_string())
}

pub fn get_variables_proxy(spec: &Implementation) -> Result <String, ()> {
    
    let mut variables : Vec<String> = Vec::new();

    for i in 0..spec.variables.len() {
            variables.push(format!("{} {} {}; \n", spec.variables[i].typ, spec.variables[i].visibility, spec.variables[i].name));
    }
    Ok(variables.join("\n"))
}

pub fn get_functions_proxy(spec: &Implementation) -> Result <String, ()> {
    
    let mut functions : Vec<String> = Vec::new();

    for i in 0..spec.functions.len() {

       if spec.functions[i].signature.kind == "function" {
            functions.push( 
                format!("function {} ({}) {} {} {} {{
                    (bool success, bytes memory bytesAnswer) = implementation.delegatecall(
                        abi.encodeWithSignature(\"{}({})\" {}));
                    require(success);
                    {}
                }}", spec.functions[i].signature.name, get_parameters_type_name_paramts(&spec.functions[i].signature.ins),
                spec.functions[i].signature.visibility, 
                get_state_mutability(&spec.functions[i].signature.state_mutability).unwrap(),
                get_parameters_type_name_return(&spec.functions[i].signature.outs).unwrap(),
                spec.functions[i].signature.name,
                get_parameters_type(&spec.functions[i].signature.ins), get_parameters_name(&spec.functions[i].signature.ins).unwrap(),
                get_parameters_type_return(&spec.functions[i].signature.outs).unwrap() ) 
            );
       }       
    }
    Ok(functions.join("\n"))
}

pub fn get_state_mutability(state_mutability: &String)  -> Result <String, ()> {
    if state_mutability != "payable"{
        return Ok("".to_string());
    }
    Ok(state_mutability.to_owned())
}

pub fn get_parameters_type_return(ret: &Vec<VariableDeclaration>) -> Result <String, ()> {
    let mut src_info : Vec<String> = Vec::new();
    if ret.len() > 0 {
        for par in ret {
            src_info.push(format!("{}", par.typ));
        }
        return Ok(format!(" return abi.decode(bytesAnswer, ( {} ) );", src_info.join(",")).to_string());
    }
    Ok("".to_string())
}

pub fn get_parameters_type_name_return(ret: &Vec<VariableDeclaration>) -> Result <String, ()> {
    let mut src_info : Vec<String> = Vec::new();
    
    if ret.len() > 0 {
        for par in ret {
            if par.storage_location == "default" {
                src_info.push(format!("{} {}", par.typ, par.name));
            } else { 
                src_info.push(format!("{} {} {}", par.typ, par.storage_location, par.name));
            }
        }
        return Ok(format!(" returns ( {} )", src_info.join(",")).to_string());
    }
    Ok("".to_string())
}

pub fn get_parameters_type_name_paramts(ins: &Vec<VariableDeclaration>) -> String {
    let mut src_info : Vec<String> = Vec::new();
    for par in ins {
        if par.storage_location == "default" {
            src_info.push(format!("{} {}", par.typ, par.name));
        } else { 
            src_info.push(format!("{} {} {}", par.typ, par.storage_location, par.name));
        }
    }
    return src_info.join(",");
}

pub fn get_parameters_type(ins: &Vec<VariableDeclaration>) -> String {
    let mut src_info : Vec<String> = Vec::new();
    for par in ins {
        src_info.push(par.typ.to_string());
    }
    return src_info.join(",");
}

pub fn get_parameters_name(ins: &Vec<VariableDeclaration>) -> Result <String, ()> {
    
    if ins.len() > 0 {
        let mut src_info : Vec<String> = Vec::new();
        for par in ins {
            src_info.push(par.name.to_string());
        }
        return Ok(format!(",{}", src_info.join(",")));
    }
    Ok("".to_string())
}