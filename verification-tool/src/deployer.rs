use async_std::task;
use std::{path::Path};
use std::fs::File;
use std::io::Read;
use web3::{
    ethabi::ethereum_types::{U256, H32, H160, H256},
    types::{Address, TransactionRequest},
    contract::{Contract, Options},
    transports::Http,
    Web3
};
use dotenv::dotenv;
use std::env;
use crate::db::{Logs};
use web3::contract::tokens::{Tokenize};
use ethabi::{Token, Param, Function, ParamType};

use crate::util::{deploy_contract_blockchain, AssignedVariable};
use crate::parser::{VariableDeclaration};


#[warn(unused_imports)]
#[tokio::main]
pub async fn deploy(spec_id:&String, author_account:&Address, name_imp_contract:&String, path_spec:&Path, 
    parameters_and_values: &mut Vec<AssignedVariable>) -> Result <Logs, String> {
    return task::block_on(deploy_contract(spec_id, author_account, &name_imp_contract, path_spec, parameters_and_values ));
}

#[warn(unused_imports)]
#[tokio::main]
pub async fn upgrade(spec_id: &String, author_account:Address, registry_address:Address, proxy_address:Address, 
    path_contract:&Path) {
    task::block_on(upgrade_contract(spec_id, author_account, registry_address, proxy_address, path_contract));
}

pub fn pad_to_bytes32(s: &[u8]) -> Option<[u8; 32]> {
    let s_len = s.len();
    if s_len > 32 {
        return None;
    }
    let mut result: [u8; 32] = Default::default();
    result[..s_len].clone_from_slice(s);
    Some(result)
}

pub fn get_connection()  -> Result <Web3<Http>, String> {
    dotenv().ok();
    let blockchain_url = env::var("BLOCKCHAIN_URL").expect("BLOCKCHAIN_URL must be set");
    let transport:Http = web3::transports::Http::new(&blockchain_url).unwrap();
    let web3:Web3<Http> = web3::Web3::new(transport);
    Ok(web3)
}


pub fn get_compiled_files(path_contract:&Path)  -> Result <String, String> {
    let mut file_contract = File::open(&path_contract).unwrap();
    let mut data_contract = String::new();
    file_contract.read_to_string(&mut data_contract).unwrap();
    Ok(data_contract)
}

pub async fn deploy_contract(spec_id:&String, author_account:&Address, name_imp_contract: &String, 
    path_spec: &Path, parameters_and_values: &mut Vec<AssignedVariable>) ->  Result <Logs, String> {
    
    let web3:Web3<Http> = get_connection().unwrap();
    
    // --------------------Deploy Registry--------------------------------------
    
    let path_registry_abi = Path::new("contracts/input/Registry.abi");
    let path_registry_bin = Path::new("contracts/input/Registry.bin");
    
    let registry_address = deploy_contract_blockchain(&author_account, &vec![].to_vec(), path_registry_bin, path_registry_abi).await.unwrap();

    // --------------------Deploy Contract--------------------

    let contract_name_abi = format!("{}.abi", &name_imp_contract);
    let contract_name_bin = format!("{}.bin", &name_imp_contract);
   
    let path_contract_abi = Path::new("contracts/input").join(&contract_name_abi);
    let path_contract_bin = Path::new("contracts/input").join(&contract_name_bin);

    let contract_address = deploy_contract_blockchain(&author_account, &* parameters_and_values, 
        path_contract_bin.as_path(), path_contract_abi.as_path()).await.unwrap();

    // -------------------- Update registry--------------------

    let registry_abi = get_compiled_files(Path::new("contracts/input/Registry.abi")).unwrap();
    let registry = Contract::from_json(web3.eth(), registry_address, registry_abi.as_bytes()).unwrap();   
    let spec_id_bytes32 = pad_to_bytes32(spec_id.as_bytes()).unwrap();
    let updated_registry = registry.call("new_mapping", (contract_address, spec_id_bytes32), *author_account, Options::default()).await;        
   
    // -------------------- Deploy proxy --------------------
    
    let proxy_file = get_compiled_files(Path::new("contracts/input/implementedproxy.sol")).unwrap();
    // let proxy_abi = get_compiled_files(Path::new("contracts/input/Proxy.abi")).unwrap();
    // let proxy_bin = get_compiled_files(Path::new("contracts/input/Proxy.bin")).unwrap();


    let path_proxy_abi = Path::new("contracts/input/Proxy.abi");
    let path_proxy_bin = Path::new("contracts/input/Proxy.bin");

    let registry_value = get_assigned_variable("address".to_string(), format!("{:?}", registry_address)).unwrap();
    let spec_id_bytes32_value = get_assigned_variable("bytes32".to_string(), std::str::from_utf8(&spec_id_bytes32.to_vec()).unwrap().to_string()).unwrap();
    let contract_address_value = get_assigned_variable("address".to_string(), format!("{:?}", contract_address)).unwrap();

    let mut vector:Vec<AssignedVariable> = vec![registry_value, spec_id_bytes32_value, contract_address_value];
    vector.append(parameters_and_values);

    let proxy_address = deploy_contract_blockchain(&author_account, &vector, path_proxy_bin, path_proxy_abi).await.unwrap();

    //read specification
    let specification = get_compiled_files(path_spec).unwrap();

    let log = Logs {
        id: 0,
        registry_address: format!("{:?}", registry.address()), 
        author_address:  format!("{:?}", *author_account), 
        specification_id: (&spec_id).to_string(),
        specification: specification, 
        proxy_address:  format!("{:?}", proxy_address),
        specification_file_name: path_spec.file_name().unwrap().to_str().unwrap().to_string(),
        proxy: proxy_file
    };

    // let proxy = Contract::from_json(web3.eth(), proxy_address, proxy_abi.as_bytes()).unwrap();   
    
    // // let result_get_selected_selected = proxy.query("get_selected", (), None, Options::default(), None);
    // // let get_selected_selected: String = result_get_selected_selected.await.unwrap();
    // // println!("selected registry -> {:?}", get_selected_selected);
   
    
    // upgrade_contract(spec_id, author_account, registry.address(), proxy.address(), 
    // Path::new("truffle/build/contracts/opposite_simple.json")  ).await;

    Ok(log)    
}

fn get_assigned_variable(typ:String, value:String) -> Result<AssignedVariable, String> {
    let assigned_variable =  AssignedVariable {
            variable_declaration: VariableDeclaration {
            visibility: "".to_string(),
            typ : typ,
            name : "".to_string(),
            storage_location : "".to_string(), 
    },
        variable_value : value,
    };
    Ok(assigned_variable)
}


async fn upgrade_contract(spec_id: &String, author_account: Address, registry_address: Address, proxy_address: Address, 
    path_contract: &Path) -> web3::Result<()> {

    let web3:Web3<Http> = get_connection().unwrap();  

    let spec_id_bytes = pad_to_bytes32(spec_id.as_bytes()).unwrap();

    // --------------------Deploy Contract--------------------

    let contract_name_abi = format!("{}.abi", &path_contract.file_stem().unwrap().to_str().unwrap());
    let contract_name_bin = format!("{}.bin", &path_contract.file_stem().unwrap().to_str().unwrap());
    

    let path_contract_abi = Path::new("contracts/input").join(&contract_name_abi);
    let path_contract_bin = Path::new("contracts/input").join(&contract_name_bin);
    let contract_address = deploy_contract_blockchain(&author_account, &vec![].to_vec(), path_contract_bin.as_path(), path_contract_abi.as_path()).await.unwrap();
   
    // -------------------- Update Registry--------------------

    let registry_abi = get_compiled_files(Path::new("contracts/input/Registry.abi")).unwrap();
    let contract_registry = Contract::from_json(web3.eth(), registry_address, registry_abi.as_bytes()).unwrap();
    let updated_registry = contract_registry.call("new_mapping", (contract_address, spec_id_bytes), author_account, Options::default()).await;        
      
    // -------------------- Upgrade Contract--------------------

    let proxy_abi = get_compiled_files(Path::new("contracts/input/Proxy.abi")).unwrap();
    let contract_proxy = Contract::from_json(web3.eth(), proxy_address, proxy_abi.as_bytes()).unwrap();
    let updated_proxy = contract_proxy.call("upgrade", (contract_address,), author_account, Options::default()).await;        

    Ok(())
}


