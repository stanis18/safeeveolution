use std::{convert::TryInto, fs::{File}, io::{Read, Write}, path::Path};

use crate::parser::{Implementation, Specification, FunctionImplementation, FunctionSpecification,VariableDeclaration};


pub fn check_synctatic_conformance(spec: &Specification, imp: &Implementation, evolution: bool) -> Result<(), String> {
   
    for i in 0..spec.variables.len() {
        let imp_var = get_variable(&spec.variables[i], &imp.variables).unwrap();
        if spec.variables[i] != imp_var {
            return Err("Incompatible variables".to_owned());
        }
    }   

    for i in 0..imp.functions.len() {
        // if imp.functions[i].signature.kind == "constructor" {
        //     return Err("The contract's implementation cannot have constructor".to_owned());
        // }
        if evolution && imp.functions[i].signature.kind == "constructor" {
            return Err("The contract's implementation cannot have initialize function".to_owned());
        }
        let func_spec = get_func_spec(&imp.functions[i], &spec.functions)?;

        if func_spec.signature != imp.functions[i].signature {
            return Err("Incompatible functions".to_owned());
        }
    }

    for i in 0..spec.functions.len() {
        
        if evolution && spec.functions[i].signature.kind == "constructor" { continue; }
            
        let func_impl = get_func_impl(&spec.functions[i], &imp.functions)?;
            
        if func_impl.signature != spec.functions[i].signature {
            return Err("Incompatible functions".to_owned());
        }
    }

    Ok(())
}

pub fn generate_merge_contract(spec: &Specification, imp: &Implementation, impl_path: &Path, out_path: &Path, evolution: bool) -> Result<String, String>{
    let merge_file_name = format!("{}", "merged_contract.sol");
    let merge_file_path = out_path.join(&merge_file_name).to_str().unwrap().to_string();
    let mut merge_file = File::create(merge_file_path.clone()).map_err( |_| {"Error creating merge".to_owned()})?;
    let mut impl_file = File::open(impl_path).map_err( |_| {"Error opening impl".to_owned()})?;
    let mut last_offset = 0;
    
    let mut buf = vec![0;imp.contract_definition.offset.try_into().unwrap()];
    impl_file.read_exact(buf.as_mut_slice()).unwrap();
    merge_file.write_all(buf.as_slice()).unwrap();
    let x = format!("/** \n * {} \n */ \n", &spec.invariant);
    merge_file.write_all(x.as_bytes()).unwrap();
    last_offset = imp.contract_definition.offset;

    for i in 0..imp.functions.len() {
        let func_impl = &imp.functions[i]; // get implementation
        let func_spec = get_func_spec(&func_impl, &spec.functions)?;
        let buf_len = (func_impl.src.offset - last_offset).try_into().unwrap(); // buff size
        let mut buf = vec![0;buf_len]; // creating buff array
        last_offset = func_impl.src.offset;
        impl_file.read_exact(buf.as_mut_slice()).unwrap(); // reading from implementation file
        merge_file.write_all(buf.as_slice()).unwrap(); // writing in merge file
        let spec = format!("/** \n * {} \n */ \n", func_spec.spec); // formating specification
        merge_file.write_all(spec.as_bytes()).unwrap(); // writing spec
    } 
    let mut rest = Vec::new();
    impl_file.read_to_end(&mut rest).unwrap();
    merge_file.write_all(rest.as_slice()).unwrap();

    Ok(merge_file_path)
}


pub fn get_func_impl(func_spec: &FunctionSpecification, imp_functions : &Vec<FunctionImplementation> ) ->  Result<FunctionImplementation, String >{
    for func in imp_functions {
       if func.signature.name == func_spec.signature.name {
        return Ok(func.clone());
       }
    }
    return Err("Missing Function".to_owned());
}


pub fn get_func_spec(func_imp: &FunctionImplementation, spec_functions : &Vec<FunctionSpecification> ) ->  Result<FunctionSpecification, String >{
    for func in spec_functions {
       if func.signature.name == func_imp.signature.name {
        return Ok(func.clone());
       }
    }
    return Err("Missing Function".to_owned());
}

pub fn get_variable(variable: &VariableDeclaration, variables_list: &Vec<VariableDeclaration>) -> Result<VariableDeclaration, String> {
    for var in variables_list {
        if variable.name == var.name {
         return Ok(var.clone());
        }
     }
     return Err("Missing Variable".to_owned());
}