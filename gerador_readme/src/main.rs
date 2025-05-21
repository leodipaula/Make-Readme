use clap::Parser;
use dotenv::dotenv;
use reqwest::Client;
use serde::Serialize;
use std::env;

#[derive(Parser, Debug)]
#[command(name = "gerador_readme")]
#[command(about = "Gera README.md com IA", long_about = None)]
struct Args {
    #[arg(long, value_name = "PROMPT", help = "Texto do prompt", required = true)]
    prompt: String,
}

#[derive(Serialize)]
struct ChatMessage {
    role: String,
    content: String,
}

#[derive(Serialize)]
struct ChatRequestPayload {
    model: String,
    messages: Vec<ChatMessage>,
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    dotenv().ok();
    let args = Args::parse();
    let token = env::var("HUGGINGFACE_API_TOKEN")?;

    let client = Client::new();
    let url = "https://router.huggingface.co/novita/v3/openai/chat/completions";

    let payload = ChatRequestPayload {
        model: "deepseek/deepseek-v3-0324".to_string(),
        messages: vec![ChatMessage {
            role: "user".to_string(),
            content: args.prompt,
        }],
    };

    let response = client
        .post(url)
        .bearer_auth(token)
        .json(&payload)
        .send()
        .await?;

    if response.status().is_success() {
        let json: serde_json::Value = response.json().await?;

        if let Some(choice) = json["choices"].get(0) {
            if let Some(message) = choice["message"]["content"].as_str() {
                println!("{}", message);
            } else {
                eprintln!("❌ Erro ao extrair a resposta da IA.");
            }
        } else {
            eprintln!("❌ Nenhuma resposta retornada.");
        }
    } else {
        let status = response.status();
        let body = response.text().await?;
        eprintln!("❌ Requisição falhou. Status: {}\nCorpo: {}", status, body);
    }

    Ok(())
}
