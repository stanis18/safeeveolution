
use dotenv::dotenv;
use std::env;
use chrono::prelude::*;
use postgres::{Client, NoTls};


#[derive(Debug,Clone)]
pub struct Logs {
    pub id: i32,
    pub registry_address: String, 
    pub author_address: String, 
    pub specification_id: String,
    pub specification: String,
    pub specification_file_name: String,
    pub proxy_address: String, 
    pub proxy: String
}

pub fn insert_on_table(log: &Logs ) -> Result<(), String> {

    dotenv().ok();
    let data_url = env::var("DATABASE_URL").expect("DATABASE_URL must be set");
    let mut client = Client::connect(&data_url, NoTls).unwrap();
    let cur_time = Utc::now();

    client.execute(
        "INSERT INTO public.logs (registry_address, author_address, specification, specification_id, proxy_address, 
            specification_file_name, proxy, created_at)  VALUES ($1, $2, $3, $4, $5, $6, $7, $8)",
        &[&log.registry_address, &log.author_address, &log.specification, &log.specification_id, 
        &log.proxy_address, &log.specification_file_name, &log.proxy, &cur_time] ).unwrap();
    Ok(())
}


pub fn select_on_table(specification_id: &String, author_address: &String) -> Result<Vec<Logs>, String> {

    dotenv().ok();
    let data_url = env::var("DATABASE_URL").expect("DATABASE_URL must be set");
    let mut client = Client::connect(&data_url, NoTls).unwrap();
    let mut list : Vec<Logs> =  Vec::new();

    for row in client.query("SELECT id, registry_address, author_address, specification_id, specification, proxy_address, 
    specification_file_name, proxy FROM logs where specification_id ilike ($1) and author_address ilike ($2)", 
    &[&specification_id, &author_address]).unwrap() {
        
        let log = Logs {
            id: row.get(0),
            registry_address: row.get(1), 
            author_address: row.get(2), 
            specification_id: row.get(3),
            specification: row.get(4),
            proxy_address: row.get(5),
            specification_file_name: row.get(6),
            proxy: row.get(7)
        };
        list.push(log);
    }
    Ok(list)
}