const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");

admin.initializeApp();

// Lista de loterias a serem gerenciadas
const lotteries = [
    "lotofacil",
    "megasena",
    "quina",
    "lotomania",
    "duplasena",
];

/**
 * Função auxiliar para buscar e atualizar resultados de uma loteria.
 *
 * @param {string} lotteryName - Nome da loteria a ser atualizada.
 * @return {Promise<void>} Retorna uma Promise que resolve quando a atualização
 * estiver concluída.
 */
async function fetchAndUpdateLottery(lotteryName) {
    const baseUrl = "https://lottolookup.com.br/api";

    try {
        const response = await axios.get(`${baseUrl}/${lotteryName}/latest`);

        if (response.status === 200) {
            const data = response.data;

            // Tratamento específico para Dupla Sena
            if (lotteryName === "duplasena") {
                data["listaDezenas"] = [
                    ...data["dezenas"]["sorteio1"].map((e) => parseInt(e)),
                    ...data["dezenas"]["sorteio2"].map((e) => parseInt(e)),
                ];
            } else {
                data["listaDezenas"] = data["listaDezenas"].map((e) =>
                    parseInt(e),
                );
            }

            data["fetchTime"] = new Date().toISOString();

            // Verifica se o resultado já existe no banco de dados
            const existingDataSnapshot = await admin
                .database()
                .ref(`lotteries/${lotteryName}`)
                .once("value");
            const existingData = existingDataSnapshot.val();

            if (
                !existingData ||
                existingData.numeroDoConcurso !== data.numeroDoConcurso
            ) {
                // Escreve no Firebase Realtime Database os dados recentes
                await admin
                    .database()
                    .ref(`lotteries/${lotteryName}`)
                    .set(data);
                console.log(`Resultados atualizados para ${lotteryName}`);

                // Adiciona ao histórico
                const concurso = data.numeroDoConcurso || data.numero;
                if (concurso) {
                    await admin
                        .database()
                        .ref(`lotteries/${lotteryName}/historical/${concurso}`)
                        .set(data);
                    console.log(`Concurso ${concurso} adicionado ao histórico de ${lotteryName}`);
                } else {
                    console.warn(`Número do concurso não encontrado para ${lotteryName}. Histórico não atualizado.`);
                }
            } else {
                console.log(`Nenhuma atualização para ${lotteryName}`);
            }
        } else {
            console.error(
                `Falha ao buscar ${lotteryName}: ${response.status}`,
            );
        }
    } catch (error) {
        console.error(`Erro ao buscar ${lotteryName}:`, error);
    }
}

/**
 * Função para popular dados históricos iniciais
 */
exports.populateInitialData = functions.https.onRequest(async (req, res) => {
    const baseUrl = "https://lottolookup.com.br/api";

    try {
        for (const lotteryName of lotteries) {
            console.log(`Buscando dados para ${lotteryName}`);
            let response;
            try {
                response = await axios.get(`${baseUrl}/${lotteryName}`);
            } catch (apiError) {
                console.error(`Erro ao buscar ${lotteryName}:`, apiError);
                continue; // Pula para a próxima loteria
            }

            if (response.status === 200) {
                const dataObject = response.data;
                console.log(`Dados recebidos para ${lotteryName}:`, dataObject);

                for (const concursoKey of Object.keys(dataObject)) {
                    try {
                        const data = dataObject[concursoKey];
                        console.log(`Processando concurso ${concursoKey} para ${lotteryName}`);

                        // Processamento específico para Dupla Sena
                        if (lotteryName === "duplasena") {
                            const sorteio1 = data["listaDezenas"] || [];
                            const sorteio2 = data["listaDezenasSegundoSorteio"] || [];

                            data["listaDezenas"] = [
                                ...sorteio1.map((e) => parseInt(e)),
                                ...sorteio2.map((e) => parseInt(e)),
                            ];
                        } else {
                            if (data["listaDezenas"]) {
                                data["listaDezenas"] = data["listaDezenas"].map((e) => parseInt(e));
                            }
                        }

                        data["fetchTime"] = new Date().toISOString();
                        const concurso = data.numero || data.numeroDoConcurso;

                        // Salvando no histórico
                        await admin
                            .database()
                            .ref(`lotteries/${lotteryName}/historical/${concurso}`)
                            .set(data);
                        console.log(`Concurso ${concurso} salvo no histórico de ${lotteryName}`);
                    } catch (concursoError) {
                        console.error(`Erro ao processar concurso ${concursoKey} para ${lotteryName}:`, concursoError);
                    }
                }
            } else {
                console.error(`Falha ao buscar ${lotteryName}: Status ${response.status}`);
            }
        }
        res.status(200).json({message: "Dados iniciais populados com sucesso."});
    } catch (error) {
        console.error("Erro ao popular dados iniciais:", error);
        res.status(500).json({error: "Erro ao popular dados iniciais."});
    }
});

/**
 * Atualiza todas as loterias de uma vez.
 *
 * @param {object} req - Objeto de requisição HTTP.
 * @param {object} res - Objeto de resposta HTTP.
 * @returns {Promise<void>} Retorna uma resposta HTTP após a execução.
 */
exports.updateAllLotteries = functions.https.onRequest(async (req, res) => {
    try {
        // Atualiza todas as loterias de uma vez
        for (const lotteryName of lotteries) {
            await fetchAndUpdateLottery(lotteryName);
        }
        res.status(200).send("Todas as loterias foram atualizadas com sucesso.");
    } catch (error) {
        console.error("Erro ao atualizar todas as loterias:", error);
        res.status(500).send("Erro ao atualizar as loterias.");
    }
});

/**
 * Funções agendadas para atualizar cada loteria em intervalos específicos.
 */

/**
 * Atualiza os resultados da Mega-Sena.
 *
 * @param {object} _context - Contexto da execução da função.
 * @returns {Promise<null>} Retorna null após a execução.
 */
exports.updateMegaSena = functions.pubsub
    .schedule("*/10 20-21 * * 3,6")
    .timeZone("America/Sao_Paulo")
    .onRun(async (_context) => {
        await fetchAndUpdateLottery("megasena");
    });

/**
 * Atualiza os resultados da Lotofácil.
 *
 * @param {object} _context - Contexto da execução da função.
 * @returns {Promise<null>} Retorna null após a execução.
 */
exports.updateLotofacil = functions.pubsub
    .schedule("*/10 20-21 * * 1,3,5")
    .timeZone("America/Sao_Paulo")
    .onRun(async (_context) => {
        await fetchAndUpdateLottery("lotofacil");
    });

/**
 * Atualiza os resultados da Quina.
 *
 * @param {object} _context - Contexto da execução da função.
 * @returns {Promise<null>} Retorna null após a execução.
 */
exports.updateQuina = functions.pubsub
    .schedule("*/10 20-21 * * 1-6")
    .timeZone("America/Sao_Paulo")
    .onRun(async (_context) => {
        await fetchAndUpdateLottery("quina");
    });

/**
 * Atualiza os resultados da Lotomania.
 *
 * @param {object} _context - Contexto da execução da função.
 * @returns {Promise<null>} Retorna null após a execução.
 */
exports.updateLotomania = functions.pubsub
    .schedule("*/10 20-21 * * 1,5")
    .timeZone("America/Sao_Paulo")
    .onRun(async (_context) => {
        await fetchAndUpdateLottery("lotomania");
    });

/**
 * Atualiza os resultados da Dupla Sena.
 *
 * @param {object} _context - Contexto da execução da função.
 * @returns {Promise<null>} Retorna null após a execução.
 */
exports.updateDuplaSena = functions.pubsub
    .schedule("*/10 20-21 * * 2,4,6")
    .timeZone("America/Sao_Paulo")
    .onRun(async (_context) => {
        await fetchAndUpdateLottery("duplasena");
    });
