extern crate dotenv;

use std::env;
use async_std::task;
use std::{path::Path, process::{Command, Stdio}};
use std::io::Read;
use std::str::FromStr;
use web3::{
    types::{Address, H160,U256},
    contract::{Contract, Options},
};
use std::fs;
use std::thread;
use std::{io};
use hex;

use crate::{checker::{check_synctatic_conformance, generate_merge_contract}, 
            parser::{parse_implementation, parse_specification,Implementation, Specification}, 
            proxy::{config_proxy}, 
            deployer::{deploy, upgrade,get_connection,get_compiled_files},
            util::{write_file, get_number_argument_constructor,delete_dir_contents,copy_dir_contents, AssignedVariable}, 
            db::{insert_on_table, select_on_table} };

mod checker;
mod parser;
mod proxy;
mod deployer;
mod util;
mod db;

// use ethabi::{Contract, Token, Param, Function, ParamType};
use std::{fs::File, io::BufReader};

use ethabi::{Token, Param, Function, ParamType};


#[warn(unused_imports)]
#[warn(bare_trait_objects)]
fn main() {

    let mut line = String::new();

    println!("O que deseja fazer? Digite 1 para deploy de um novo contrato, Digite 2 para upgrade de um contrato:");
    std::io::stdin().read_line(&mut line).unwrap();
    let option = line.trim().parse::<i32>().unwrap_or(0);
    line.clear();
   
    if option == 1 {

        println!("Insert the specification path:");
        std::io::stdin().read_line(&mut line).unwrap();
        let spec_url = line.trim().clone().to_string();
        line.clear();
        
        // // let spec_url = "truffle/contracts/simpleSpec.sol";
        let spec = get_specification(Path::new(&spec_url)).unwrap();
        
        println!("Insert the implementation path:");
        std::io::stdin().read_line(&mut line).unwrap();
        let impl_url = line.trim().clone().to_string();
        line.clear();
        
        // let impl_url = "truffle/contracts/simple.sol";
        let imp = get_implementation(Path::new(&impl_url)).unwrap();

        println!("{:?}", imp.contracts_inherited);
       
        println!("Insert the specification Id:");
        std::io::stdin().read_line(&mut line).unwrap();
        let spec_id = line.trim().clone().to_string();
        line.clear();

        println!("Insert the wallet address:");
        std::io::stdin().read_line(&mut line).unwrap();
        let wallet_address = Address::from_str(line.trim().clone()).unwrap();
        line.clear();

        let constructor_arguments = get_number_argument_constructor(&imp).unwrap();
        let mut parameters_and_values: Vec<AssignedVariable> = Vec::new();

        for i in 0..constructor_arguments.len() {
            println!("Insert the value of the constructor variable {:?}: ", constructor_arguments[i].name);
            std::io::stdin().read_line(&mut line).unwrap();
            let value = line.trim().clone().to_string();
            line.clear();

            let variable_value = AssignedVariable {
                variable_declaration: constructor_arguments[i].clone(),
                variable_value: value,
            };
            parameters_and_values.push(variable_value);
        }

        deploy_contract(Path::new(&impl_url), Path::new(&spec_url), &imp, &spec, &spec_id, &wallet_address, &mut parameters_and_values);
        // delete_dir_contents();
    } else if option == 2 {

        // let impl_url = "truffle/contracts/OppositeSimple.sol";
        println!("Insert the implementation path:");
        std::io::stdin().read_line(&mut line).unwrap();
        let impl_path = line.trim().clone().to_string();
        line.clear();
      
        println!("Insert the specification Id:");
        std::io::stdin().read_line(&mut line).unwrap();
        let spec_id = line.trim().clone().to_string();
        line.clear();

        println!("Insert the wallet address:");
        std::io::stdin().read_line(&mut line).unwrap();
        let wallet_address = Address::from_str(line.trim().clone()).unwrap();
        line.clear();

        upgrade_contract(Path::new(&impl_path), &spec_id, &wallet_address);
        delete_dir_contents();
    } else {
        println!("{}", "Invalid Option!");
    }
    
}


pub fn get_implementation(impl_url: &Path) -> Result<Implementation, String>{

    let impl_path_output = Path::new("contracts/input").join(&impl_url.file_name().unwrap().to_str().unwrap());
    fs::copy(&impl_url.to_path_buf(), &impl_path_output);

    generate_ast_contract(impl_path_output.file_name().unwrap().to_str().unwrap());

    let imp_path = Path::new("contracts/input");
    let impl_json_path = format!("{}_json.ast", Path::new(&impl_path_output).file_name().unwrap().to_str().unwrap());
    let imp = parse_implementation(&imp_path.join(&impl_json_path).as_path()).expect("Expected implementation");
    Ok(imp)
}

pub fn get_specification(spec_url: &Path) -> Result<Specification, String>{

    let spec_path_output = Path::new("contracts/input").join(&spec_url.file_name().unwrap().to_str().unwrap());    
    fs::copy(&spec_url.to_path_buf(), &spec_path_output);

    generate_ast_contract(spec_path_output.file_name().unwrap().to_str().unwrap());

    let inp_path = Path::new("contracts/input");
    let spec_json_path = format!("{}_json.ast", Path::new(&spec_path_output).file_name().unwrap().to_str().unwrap());
    let spec = parse_specification(&inp_path.join(&spec_json_path).as_path()).expect("Expected specification");
    Ok(spec)
}


pub fn deploy_contract(impl_path_input: &Path, spec_path_input: &Path, imp: &Implementation, 
    spec: &Specification, spec_id: &String, author_account: &Address, parameters_and_values: &mut Vec<AssignedVariable>){
   
    fs::copy("contracts/registry.sol", "contracts/input/registry.sol");
    generate_compiled_contract("registry.sol");

    //copying the implementation file    
    let impl_path_output = Path::new("contracts/input").join(&impl_path_input.file_name().unwrap().to_str().unwrap());

    //copying the specification file        
    let spec_path_output = Path::new("contracts/input").join(&spec_path_input.file_name().unwrap().to_str().unwrap());    
        
    let inp_path = Path::new("contracts/input");

    if let Err(s) = check_synctatic_conformance(&spec, &imp, false) {
        println!("Found an error: {}", s);
        return;
    }

    //generating merged contract
    let res_merge = generate_merge_contract(&spec, &imp, Path::new(&impl_path_output), &inp_path, false);

    if let Err(s) = &res_merge {
        println!("Found an error: {}", s);
        return;
    }

    verify_contract();
    
    generate_compiled_contract(&impl_path_output.file_name().unwrap().to_str().unwrap());
       
    config_proxy(&imp, Path::new(&impl_path_output));
    generate_compiled_contract("implementedproxy.sol");

    let log = deploy(&spec_id, author_account, &imp.contract_name, &spec_path_output, parameters_and_values);
    
    insert_on_table(&log.unwrap());

}


pub fn upgrade_contract(impl_path_input: &Path, spec_id: &String, author_account: &Address){

    //copying registry
    fs::copy("contracts/registry.sol", "contracts/input/registry.sol");

    //copying the implementation file    
    let mut impl_path_output = Path::new("contracts/input").join(&impl_path_input.file_name().unwrap().to_str().unwrap());
    fs::copy(&impl_path_input, &impl_path_output);

    let log = select_on_table(spec_id, &format!("{:?}", author_account)).unwrap();

    write_file(&log[0].specification, &log[0].specification_file_name );
    write_file(&log[0].proxy, &"implementedproxy.sol".to_string() );
    
    //generating ast for the specification file
    generate_ast_contract(&log[0].specification_file_name);
    
    let inp_path = Path::new("contracts/input");
    
    let spec = get_specification(inp_path.join(&log[0].specification_file_name).as_path()).expect("Expected specification");
    let imp = get_implementation(&impl_path_input).unwrap();

    if let Err(s) = check_synctatic_conformance(&spec, &imp, true) {
        println!("Found an error: {}", s);
        return;
    }

    let res_merge = generate_merge_contract(&spec, &imp, Path::new(&impl_path_output), &inp_path, true);

    if let Err(s) = &res_merge {
        println!("Found an error: {}", s);
        return;
    }

    verify_contract();
 
    generate_compiled_contract(&impl_path_output.file_name().unwrap().to_str().unwrap());
    
    generate_compiled_contract(&"implementedproxy.sol");

    upgrade(&log[0].specification_id, Address::from_str(&log[0].author_address).unwrap(), 
    Address::from_str(&log[0].registry_address).unwrap(), Address::from_str(&log[0].proxy_address).unwrap(), &impl_path_output);

}


pub fn generate_ast_contract(file_name: &str) -> Result <(), String> {
    let path = env::current_dir().unwrap();
    let command = format!("docker run --rm -v {}/contracts/input:/sources ethereum/solc:0.5.17 -o sources --ast-compact-json  /sources/{} --overwrite",
    path.to_str().unwrap(), &file_name);

    let com = Command::new("cmd").args(&["/C", &command]).stdin(Stdio::piped())
    .stdout(Stdio::piped()).spawn().expect("echo command failed to start");

    let mut answer = String::new();
    match com.stdout.unwrap().read_to_string(&mut answer) {
        Err(why) => panic!("Couldn't generate ast tree: {}", why),
        Ok(_) => print!("Tree generated with sucess:\n{}", answer),
    }
   Ok(())
}

pub fn verify_contract() -> Result <(), String> {
    let path = env::current_dir().unwrap();
    let command = format!("docker run --rm -v {}/contracts/input:/contracts solc-verify:0.7 /contracts/merged_contract.sol",
    path.to_str().unwrap());

    let com = Command::new("cmd").args(&["/C", &command]).stdin(Stdio::piped())
    .stdout(Stdio::piped()).spawn().expect("echo command failed to start");

    let mut answer = String::new();
    match com.stdout.unwrap().read_to_string(&mut answer) {
        Err(why) => panic!("Couldn't verify the contract {} :", why ),
        Ok(_) => print!("Contract verifyed with sucess:\n{}", answer),
    }

    Ok(())
}

pub fn generate_compiled_contract(file_name: &str) -> Result <(), String> {
    let path = env::current_dir().unwrap();
    let command = format!("docker run --rm -v {}/contracts/input:/sources ethereum/solc:0.5.17 -o sources --bin --abi  /sources/{} --overwrite",
    path.to_str().unwrap(), &file_name);
    
    let com = Command::new("cmd").args(&["/C", &command]).stdin(Stdio::piped())
    .stdout(Stdio::piped()).spawn().expect("echo command failed to start");

    let mut answer = String::new();
    match com.stdout.unwrap().read_to_string(&mut answer) {
        Err(why) => panic!("Couldn't compile the contract {} : {}", why, file_name),
        Ok(_) => print!("Contract compiled with sucess:\n{}", answer),
    }
   Ok(())
}



#[cfg(test)]
mod tests {
    use super::*;

    #[actix_rt::test]
    async fn deploy_simple_contract() {
        let web3 = get_connection().unwrap(); 
        let spec_url = "tests/SimpleSpec.sol";
        let spec = get_specification(Path::new(&spec_url)).unwrap();
        let impl_url = "tests/Simple.sol";
        let imp = get_implementation(Path::new(&impl_url)).unwrap();
        let spec_id = "simple".to_string();
        let mut accounts = web3.eth().accounts().await.unwrap();

        let values = vec!["5".to_string(),"6".to_string(),"false".to_string()];
        let constructor_arguments = get_number_argument_constructor(&imp).unwrap();
        let mut parameters_and_values: Vec<AssignedVariable> = Vec::new();

        for i in 0..constructor_arguments.len() {
            let variable_value = AssignedVariable {
                variable_declaration: constructor_arguments[i].clone(),
                variable_value: values[i].clone(),
            };
            parameters_and_values.push(variable_value);
        }
        
        tokio::task::spawn_blocking( move || { 
            deploy_contract(Path::new(&impl_url), Path::new(&spec_url), &imp, &spec, &"simple".to_string(), &accounts[0], 
            &mut parameters_and_values); }).await.expect("Task panicked");
        accounts = web3.eth().accounts().await.unwrap();  
        let log = select_on_table(&spec_id.clone(), &format!("{:?}", accounts[0])).unwrap();    
        
        let proxy_abi = get_compiled_files(Path::new("contracts/input/Proxy.abi")).unwrap();
        
        let proxy_contract = Contract::from_json(web3.eth(), Address::from_str(&log[0].proxy_address).unwrap(), 
        proxy_abi.as_bytes()).unwrap();
        
        let result = proxy_contract.query("get_selected", (), None, Options::default(), None);
        let selected: U256 = result.await.unwrap();
        assert_eq!(selected, web3::types::U256::from(6));

        delete_dir_contents();
        
        let impl_evol = "tests/SimpleEvol.sol";
       
        tokio::task::spawn_blocking( move || {     
        upgrade_contract( Path::new(&impl_evol), &spec_id, &accounts[0]); })
                    .await.expect("Task panicked");

        let result_updated = proxy_contract.query("get_selected", (), None, Options::default(), None);
        let selected_updated: U256 = result_updated.await.unwrap();
        assert_eq!(selected_updated, web3::types::U256::from(5));
       
        delete_dir_contents();
    }

    // #[actix_rt::test]
    // async fn deploy_reentrancy_contract() {
    //     let web3 = get_connection().unwrap(); 
    //     let spec_url = "tests/ReentrancySpec.sol";
    //     let spec = get_specification(Path::new(&spec_url)).unwrap();
    //     let impl_url = "tests/Reentrancy.sol";
    //     let imp = get_implementation(Path::new(&impl_url)).unwrap();
    //     let spec_id = "reentrancy".to_string();
    //     let mut accounts = web3.eth().accounts().await.unwrap();
    //     tokio::task::spawn_blocking( move || { 
    //         deploy_contract(Path::new(&impl_url), Path::new(&spec_url), &imp, &spec, &"reentrancy".to_string(), &accounts[0], vec![]); })
    //             .await.expect("Task panicked");
    //     accounts = web3.eth().accounts().await.unwrap();
    //     let log = select_on_table(&spec_id.clone(), &format!("{:?}", accounts[0])).unwrap();    
        
    //     let proxy_abi = get_compiled_files(Path::new("contracts/input/Proxy.abi")).unwrap();
        
    //     let proxy_contract = Contract::from_json(web3.eth(), Address::from_str(&log[0].proxy_address).unwrap(), 
    //     proxy_abi.as_bytes()).unwrap();

    //     proxy_contract.call("deposit", (),  accounts[0], Options::with(|opt| {
    //         opt.value = Some(10000.into()); opt.gas_price = Some(5.into()); opt.gas = Some(3_000_000.into()); })).await;
        
    //     let balance:U256 = proxy_contract.query("getBalance", (), None, Options::default(), None).await.unwrap();
    //     assert_eq!(balance, U256::from(10000));

    //     delete_dir_contents();

    //     let impl_evol = "tests/ReentrancyEvol.sol";
       
    //     tokio::task::spawn_blocking( move || {     
    //             upgrade_contract( Path::new(&impl_evol), &spec_id, &accounts[0]); })
    //             .await.expect("Task panicked");
    //     accounts = web3.eth().accounts().await.unwrap();  

    //     proxy_contract.call("deposit", (),  accounts[0], Options::with(|opt| {
    //         opt.value = Some(10000.into()); opt.gas_price = Some(5.into()); opt.gas = Some(3_000_000.into());})).await;

    //     let balance:U256 = proxy_contract.query("getBalance", (), None, Options::default(), None).await.unwrap();
    //     assert_eq!(balance, U256::from(10000));

    //     proxy_contract.call("deposit", (),  accounts[0], Options::with(|opt| {
    //         opt.value = Some(20000.into()); opt.gas_price = Some(5.into()); opt.gas = Some(3_000_000.into()); })).await;
        
    //     let balance:U256 = proxy_contract.query("getBalance", (), None, Options::default(), None).await.unwrap();
    //     assert_eq!(balance, U256::from(30000));
    //     delete_dir_contents();
    // }    

    // #[actix_rt::test]   
    // async fn deploy_food_token() {
    //     copy_dir_contents("tests/folder_", "contracts/input");
    //     let web3 = get_connection().unwrap(); 
    //     let spec_url = "tests/FoodTokenSpec.sol";
    //     let spec = get_specification(Path::new(&spec_url)).unwrap();
    //     let impl_url = "tests/FoodToken.sol";
    //     let imp = get_implementation(Path::new(&impl_url)).unwrap();
    //     let spec_id = "foodtoken".to_string();
    //     let mut accounts = web3.eth().accounts().await.unwrap();
    //     tokio::task::spawn_blocking( move || { 
    //         deploy_contract(Path::new(&impl_url), Path::new(&spec_url), &imp, &spec, &"foodtoken".to_string(), &accounts[0], vec![]); })
    //             .await.expect("Task panicked");
    //     accounts = web3.eth().accounts().await.unwrap();
    //     let log = select_on_table(&spec_id.clone(), &format!("{:?}", accounts[0])).unwrap();    
    
    // }

}