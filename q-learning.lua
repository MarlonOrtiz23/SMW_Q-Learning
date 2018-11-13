acoes = {"P1 Right","P1 X","P1 A","P1 B"}; -- 2; 3; 4;
comandos = {};
inicio = "inicio.state"
states = {};

function getElementos()
	posX = memory.read_s16_le(0x94);
	posY = memory.read_s16_le(0x96);
	
	--posXtela = memory.read_s16_le(0x7E);
	--posYtela = memory.read_s16_le(0x80);
	
	score = memory.read_s24_le(0xF34);
	coins = memory.readbyte(0xDBF);
	
	marioMorre = memory.readbyte(0x71); -- 9 = morte
	
	sprites = {};
	for i = 1, 12 do
		sprites[i] = {0,0,0,0}; -- {posX,posY,status,id}
	end
	
	inimigosStatusaux = memory.readbyterange(0x14C8,12); -- > 7
	for i = 0, 11 do
		sprites[i+1][3] = memory.readbyte(0x14C8+i);
	end
	
	-- 0x14E0 Sprite X position, high byte.
	-- 0xE4 Sprite X position, low byte.
	-- 0x14D4 Sprite Y position, high byte.
	-- 0xD8 Sprite Y position, low byte.
	
	for i = 0, 11 do
		high = memory.readbyte(0x14E0+i);
		low = memory.readbyte(0xE4+i);
		sprites[i+1][1] = bit.bor(low,(bit.lshift(high,8)));
	end
	
	for i = 0, 11 do
		high = memory.readbyte(0x14D4+i);
		low = memory.readbyte(0xD8+i);
		sprites[i+1][2] = bit.bor(low,(bit.lshift(high,8)));
	end
	
end

function resetControl(acao)
	for i = 1, 4 do
		comandos[acoes[i]] = false;
	end
	joypad.set(comandos);
	
	if acao == 0 then
		do return end
	end
	
	comandos[acoes[1]] = true; -- ir para direita
	
	comandos[acoes[acao]] = true;

end

--estado = 0;
objetivoX = 4823; --4823;
posX = 0;
posXanterior = 0;
--estadoAnterior = 0;
indiceMax = 0;

--acao = 0;
melhorScore = 0;

function saveStates()
	file = io.open("states.txt","w+");
	io.output(file);
	io.write(indiceMax .. "\n");
	for i = 1,indiceMax do
		io.write(states[i][1] .. "\n");
	end
	io.close(file);
end

function copyStates()
	file = io.open("states.txt","r");
	if file == nil then
		indiceMax = 0;
		file = io.open("states.txt","w+");
		io.input(file);
		io.write("0\n");
	else
		io.input(file);
		indiceMax = tonumber(io.read());
		for i = 1, indiceMax do
			states[i] = {};
			states[i] = {io.read(),0,0,0};
		end
	end
	io.close(file);
end

function saveQValues()
	file = io.open("qvalues.txt","w+");
	io.output(file);
	for i = 1,indiceMax do
		for j = 2, 4 do
			io.write(states[i][j] .. "\n");
		end
	end
	io.close(file);
end

function copyQValues()
	file = io.open("qvalues.txt","r");
	io.input(file);
	--liness = io.read("*all");
	--i = 1;
	--for line in liness:gmatch("([^\n]*)\n?") do
	for i = 1, indiceMax do
		for j = 2, 4 do
			states[i][j] = tonumber(io.read());
		end
		--i = i+1;
	end
	io.close(file);
end

function saveNValues()
	file = io.open("nvalues.txt","w+");
	io.output(file);
	for i = 1,indiceMax do
		for j = 2, 4 do
			io.write(ntable[i][j] .. "\n");
		end
	end
	io.close(file);
end

function copyNValues()
	file = io.open("nvalues.txt","r");
	io.input(file);
	for i = 1, indiceMax do
		for j = 2, 4 do
			ntable[i][j] = tonumber(io.read());
		end
		--i = i+1;
	end
	io.close(file);
end

function backupFiles()
	file = io.open("nvalues" .. scoreNumber .. ".txt","w+");
	io.output(file);
	for i = 1,indiceMax do
		for j = 2, 4 do
			io.write(ntable[i][j] .. "\n");
		end
	end
	io.close(file);
	
	file = io.open("qvalues" .. scoreNumber .. ".txt","w+");
	io.output(file);
	for i = 1,indiceMax do
		for j = 2, 4 do
			io.write(states[i][j] .. "\n");
		end
	end
	io.close(file);
	
	file = io.open("states" .. scoreNumber .. ".txt","w+");
	io.output(file);
	io.write(indiceMax .. "\n");
	for i = 1,indiceMax do
		io.write(states[i][1] .. "\n");
	end
	io.close(file);
	
end

scoreNumber = 0;

function saveScore()
	file = io.open("scores" .. scoreNumber .. ".txt","a+");
	io.output(file);
	io.write(score .. "\n");
	io.close(file);
end

function savePosX()
	file = io.open("posx.txt","a+");
	io.output(file);
	io.write(posX .. "\n");
	io.close(file);
end

function getEstadoIndex(eestado)
	for j = 1, indiceMax do
		if states[j] ~= nil and states[j][1] == eestado then
			return j;
		end
	end
	return -1;
end

function getEstado()
	local estadoo;
	estadoo = posX .. "," .. posY;
	for i = 1, 12 do
		if sprites[i][3] > 7 then
			estadoo = estadoo .. "-" .. sprites[i][1] .. "," .. sprites[i][2];
		end
	end
	return estadoo;
end

copyStates();

ntable = {};
for i = 1, indiceMax do
	ntable[i] = {};
	for j = 2, 4 do
		ntable[i][j] = 0;
	end
end

index = nil;

function getAcao()
	pior = nil;
	melhor = nil;
	acao = nil;
	
	lista = nil;
	for i = 2, 4 do -- para todas as ações
		aux = ntable[index][i];
		if i == 2 then
			pior = aux;
			acao = i;
		elseif aux < pior then
			pior = aux;
			acao = i;
			lista = nil;
		elseif aux == pior then
			if lista == nil then
				lista = {};
				lista[1] = i;
				lista[2] = acao;
				indexLista = 2;
			else
				indexLista = indexLista+1;
				lista[indexLista] = i;
			end
		end
	end
	
	if pior > menor then
	--if true then
		lista = nil;
		for i = 2, 4 do -- para todas as ações
			aux = states[index][i];
			if i == 2 then
				melhor = aux;
				acao = i;
			elseif aux > melhor then
				melhor = aux;
				acao = i;
				lista = nil;
			elseif aux == melhor then
				if lista == nil then
					lista = {};
					lista[1] = i;
					lista[2] = acao;
					indexLista = 2;
				else
					indexLista = indexLista+1;
					lista[indexLista] = i;
				end
			end
		end
	end
	
	if lista ~= nil then
		acao = lista[math.random(1,indexLista)];
	end
	
	return acao;
end

function qlearning()
	reward = 0;
	rewardAnterior = 0;
	estado = nil;
	acao = nil;
	indexAnterior = nil;
	score = 0;
	scoreAnterior = 0;
	coinsAnterior = 0;
	terminal = 0;

	--index = math.random(1,indiceMax);
	savestate.load(inicio);
	--savestate.load("estados/" .. index);
	getElementos();
	estado = getEstado();
	index = getEstadoIndex(estado);
	
	while true do
		if index == -1 then
			indiceMax = indiceMax + 1;
			states[indiceMax] = {estado,0,0,0};
			index = indiceMax;
			ntable[index] = {};
			for j = 2, 4 do
				ntable[index][j] = 0;
			end
			--saveStates();
			--saveQValues();
			--saveNValues();
		end
		
		acao = getAcao();
		
		resetControl(0);
		joypad.set(comandos);
		emu.frameadvance();
		
		resetControl(acao);
		terminal = 0;
		local cont = 1;
		
		rewardAnterior = reward;
		reward = 0;
		scoreAnterior = score;
		coinsAnterior = coins;
		indexAnterior = index;
		posXanterior = posX;
		--print("index " .. index .. " acao " .. acao);
		
		ntable[index][acao] = ntable[index][acao]+1;
	
		for j = 1, frames do -- realiza ação
			joypad.set(comandos);
			emu.frameadvance();
			local xAux = posX;
			getElementos();
			--print(marioMorre);
			if marioMorre == 9 then -- verifica se morreu a cada frame
				reward = -100;
				terminal = 1;
				--savePosX();
				break;
			end
			
			if cont == frames then
				reward = -100;
				terminal = 1;
				--savePosX();
				break;
			end
			
			if posX > objetivoX then -- verifica o objetivo
				reward = (coins - coinsAnterior)+((score - scoreAnterior)/10)+100;
				terminal = 1;
				--exploration = exploration-0.1;
				saveScore();
				break;
			end
			
			if posX == xAux then
				cont = cont+1;
			end
		end
		
		--reward = reward + ((posX-posXanterior)/100);
		
		if terminal == 0 then
			reward = (coins - coinsAnterior)+(score - scoreAnterior)/10;
		end
		
		--print("coins: " .. coins .. " coinsAnterior: " .. coinsAnterior .. "\nscore: " .. score .. " scoreAnterior: " .. scoreAnterior .. "\nreward: " .. reward .. "\n");
		
		if terminal == 1 then
			states[indexAnterior][acao] = reward;
			break;
		end
		
		getElementos();
		estado = getEstado();
		index = getEstadoIndex(estado);
		
		melhor = nil;
		if index == -1 then
			melhor = 0;
		else
			for i = 2, 4 do -- para todas as ações
				aux = states[index][i];
				if i == 2 then
					melhor = aux;
				elseif aux > melhor then
					melhor = aux;
				end
			end
		end
		
		qval = states[indexAnterior][acao] + (learningRate*ntable[indexAnterior][acao])*(reward + (discount*melhor) - states[indexAnterior][acao]);
		--print("qvalue: " .. qval .. "\n");
		
		
		--if qval < -1000000000 then
		--	qval = -1000000000;
		--elseif qval > 1000000000 then
		--	qval = 1000000000;
		--end
		
		states[indexAnterior][acao] = qval;
		--print("estado: " .. indexAnterior .. " acao: " .. acao .. " qvalue: " .. states[indexAnterior][acao] .. " frequencia: " .. ntable[indexAnterior][acao]);
	end
	
	--print("score: " .. score);
	saveStates();
	saveQValues();
	saveNValues();
end

function verifica()
	ret = 1;
	for i = 1, indiceMax do
		for j = 2, 4 do
			if ntable[i][j] < menor then
				ret = 0;
				break;
			end
		end
		if ret == 0 then break end;
	end
	return ret;
end

function treino()
	for it = 1, 3 do
		scoreNumber = it;
		print("\ninicio" .. scoreNumber .. ": " .. os.date("%c"));
		for i = 1, 1000 do
			qlearning();
			--if verifica() == 0 then
			--	print("yes");
			--end
		end
		print("\ntermino" .. scoreNumber .. ": " .. os.date("%c"));
		backupFiles();
	end
end

frames = 30; -- quantidade de frames para cada ação
menor = 5; --exploration
saveQValues(); -- se quiser zerar os qvalues -----------------------------------------------
copyQValues();
saveNValues(); -- se quiser zerar os nvalues
copyNValues();
learningRate = 0.0001;
discount = 0.1;

treino();
--os.execute("shutdown %-s %-t 01");