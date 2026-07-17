(function(){
  "use strict";

  var menuButton=document.querySelector(".menu-toggle");
  var nav=document.getElementById("site-nav");
  function closeMenu(){
    if(!menuButton||!nav)return;
    nav.classList.remove("open");
    menuButton.setAttribute("aria-expanded","false");
  }
  if(menuButton&&nav){
    menuButton.addEventListener("click",function(){
      var open=!nav.classList.contains("open");
      nav.classList.toggle("open",open);
      menuButton.setAttribute("aria-expanded",open?"true":"false");
    });
    document.addEventListener("click",function(event){
      if(nav.classList.contains("open")&&!event.target.closest("header"))closeMenu();
    });
    document.addEventListener("keydown",function(event){if(event.key==="Escape")closeMenu();});
  }

  var downloadLink=document.querySelector(".download-action .button");
  var downloadMeta=document.getElementById("zipmeta");
  if(downloadLink&&downloadMeta){
    downloadLink.addEventListener("click",function(){downloadMeta.textContent="Download started — extract it onto your USB";});
  }

  var reducedMotion=window.matchMedia&&window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  var anchors=document.querySelectorAll('a[href^="#"]');
  for(var anchorIndex=0;anchorIndex<anchors.length;anchorIndex++){
    anchors[anchorIndex].addEventListener("click",function(event){
      var id=this.getAttribute("href").slice(1);
      var target=document.getElementById(id);
      closeMenu();
      if(target&&target.scrollIntoView){
        event.preventDefault();
        target.scrollIntoView({behavior:reducedMotion?"auto":"smooth",block:"start"});
        if(window.history&&window.history.replaceState)window.history.replaceState(null,"","#"+id);
      }
    });
  }

  var root=document.getElementById("plugcade-live-demo");
  if(!root)return;
  var screen=root.querySelector(".pcd-screen");
  var bootLog=root.querySelector(".pcd-boot-log");
  var canvas=root.querySelector(".pcd-canvas");
  var ctx=canvas&&canvas.getContext?canvas.getContext("2d"):null;
  var gameView=root.querySelector(".pcd-game-view");
  var scoreEl=root.querySelector(".pcd-score");
  var timeEl=root.querySelector(".pcd-time");
  var livesEl=root.querySelector(".pcd-lives");
  var hudLabel=root.querySelector(".pcd-hud-label");
  var gameNameEl=root.querySelector(".pcd-game-name");
  var finalScore=root.querySelector(".pcd-final-score");
  var result=root.querySelector(".pcd-result");
  var playTitle=root.querySelector(".pcd-play-title");
  var usbButton=root.querySelector(".pcd-insert");
  var usbHint=root.querySelector(".pcd-usb-hint");
  var soundButton=root.querySelector(".pcd-sound");
  var tiles=root.querySelectorAll(".pcd-library-tile");
  if(!screen||!bootLog||!ctx||!gameView||!usbButton||!tiles.length)return;

  var games=[
    {id:"stars",name:"STAR CATCHER",metric:"STARS",label:"Move left and right to catch yellow stars and avoid red glitches."},
    {id:"moon",name:"MOON HOPPER",metric:"HOPS",label:"Steer the moon explorer onto floating platforms and keep bouncing."},
    {id:"rocket",name:"ROCKET RUN",metric:"POINTS",label:"Fly through the star lane, collect energy diamonds and dodge asteroids."},
    {id:"breaker",name:"PIXEL BREAKER",metric:"BRICKS",label:"Move the paddle to bounce the ball and clear the pixel wall."}
  ];
  var selectedGame=0;
  var running=false,raf=0,last=0,elapsed=0,spawnClock=0,score=0,lives=3;
  var moveLeft=false,moveRight=false;
  var player={x:285,y:318,w:70,h:18,speed:330};
  var objects=[],platforms=[],bricks=[],stars=[];
  var ball={x:320,y:280,vx:180,vy:-205,r:8};
  var bootTimers=[];
  var audioEnabled=false,audioContext=null;

  function css(name){return window.getComputedStyle(root).getPropertyValue(name).trim();}
  function setState(state){screen.setAttribute("data-state",state);}
  function addBootLine(text){var line=document.createElement("div");line.textContent=text;bootLog.appendChild(line);}
  function later(fn,delay){bootTimers.push(window.setTimeout(fn,delay));}
  function buzz(pattern){if(navigator.vibrate)navigator.vibrate(pattern);}
  function beep(frequency,duration,type){
    if(!audioEnabled)return;
    try{
      var AudioContext=window.AudioContext||window.webkitAudioContext;
      if(!AudioContext)return;
      if(!audioContext)audioContext=new AudioContext();
      var oscillator=audioContext.createOscillator();
      var gain=audioContext.createGain();
      oscillator.type=type||"square";
      oscillator.frequency.value=frequency;
      gain.gain.setValueAtTime(.035,audioContext.currentTime);
      gain.gain.exponentialRampToValueAtTime(.001,audioContext.currentTime+duration);
      oscillator.connect(gain);gain.connect(audioContext.destination);
      oscillator.start();oscillator.stop(audioContext.currentTime+duration);
    }catch(error){audioEnabled=false;}
  }

  function selectGame(index,focusTile){
    selectedGame=(index+games.length)%games.length;
    for(var i=0;i<tiles.length;i++){
      var selected=i===selectedGame;
      tiles[i].classList.toggle("is-selected",selected);
      tiles[i].setAttribute("aria-pressed",selected?"true":"false");
    }
    playTitle.textContent=games[selectedGame].name;
    if(focusTile&&tiles[selectedGame].focus)tiles[selectedGame].focus();
    beep(240+selectedGame*70,.045,"square");
  }

  function boot(){
    for(var i=0;i<bootTimers.length;i++)window.clearTimeout(bootTimers[i]);
    bootTimers=[];
    root.classList.add("is-inserted");
    usbButton.disabled=true;
    usbButton.setAttribute("aria-label","Plugcade USB inserted");
    usbHint.textContent="USB CONNECTED — BOOTING PLUGCADE";
    beep(160,.09,"square");
    var insertionDelay=reducedMotion?0:420;
    later(function(){
      setState("boot");bootLog.textContent="";addBootLine("CHECKING USB...");beep(210,.06,"square");
    },insertionDelay);
    later(function(){addBootLine("FOUND PLUGCADE 0.4");beep(280,.05,"square");},insertionDelay+310);
    later(function(){addBootLine("KID MODE: READY");beep(360,.05,"square");},insertionDelay+650);
    later(function(){addBootLine("4 GAMES FOUND");beep(480,.08,"square");},insertionDelay+940);
    later(function(){
      setState("library");usbHint.textContent="PLUGCADE USB — CONNECTED";selectGame(0,false);
      if(tiles[0].focus)tiles[0].focus();
    },reducedMotion?260:insertionDelay+1320);
  }

  function randomStars(){
    stars=[];
    for(var i=0;i<44;i++)stars.push({x:(i*83+31)%640,y:(i*47+17)%360,s:i%3+1});
  }
  function initGame(id){
    objects=[];platforms=[];bricks=[];randomStars();spawnClock=0;
    if(id==="stars"){
      player={x:285,y:318,w:70,h:18,speed:340};
    }else if(id==="moon"){
      player={x:303,y:296,w:30,h:30,speed:255,vy:-445};
      platforms=[
        {x:270,y:338,w:100,h:11},{x:82,y:278,w:112,h:11},{x:272,y:220,w:105,h:11},
        {x:468,y:164,w:106,h:11},{x:245,y:108,w:105,h:11},{x:50,y:54,w:100,h:11}
      ];
    }else if(id==="rocket"){
      player={x:298,y:300,w:44,h:42,speed:365};
    }else{
      player={x:273,y:330,w:94,h:14,speed:380};
      ball={x:320,y:292,vx:185,vy:-215,r:8};
      for(var row=0;row<4;row++){
        for(var col=0;col<7;col++)bricks.push({x:27+col*87,y:42+row*33,w:77,h:21,row:row});
      }
    }
  }

  function resetGame(){
    running=true;last=0;elapsed=0;score=0;lives=3;moveLeft=false;moveRight=false;
    scoreEl.textContent="0";timeEl.textContent="20";livesEl.textContent="3";
    hudLabel.textContent=games[selectedGame].metric;gameNameEl.textContent=games[selectedGame].name;
    canvas.setAttribute("aria-label",games[selectedGame].name+" game. "+games[selectedGame].label);
    initGame(games[selectedGame].id);
    gameView.classList.remove("is-over");setState("game");
    window.cancelAnimationFrame(raf);screen.focus();beep(520,.08,"square");
    raf=window.requestAnimationFrame(frame);
  }

  function hitCircleRect(circle,box){
    var x=Math.max(box.x,Math.min(circle.x,box.x+box.w));
    var y=Math.max(box.y,Math.min(circle.y,box.y+box.h));
    var dx=circle.x-x,dy=circle.y-y;
    return dx*dx+dy*dy<circle.r*circle.r;
  }
  function movePlayer(dt){
    if(moveLeft)player.x-=player.speed*dt;
    if(moveRight)player.x+=player.speed*dt;
    player.x=Math.max(0,Math.min(canvas.width-player.w,player.x));
  }
  function changeLives(amount){
    lives=Math.max(0,lives+amount);livesEl.textContent=String(lives);
    if(amount<0){buzz(45);beep(105,.12,"sawtooth");}
  }
  function addScore(amount){
    score+=amount;scoreEl.textContent=String(score);buzz(12);beep(650+Math.min(score,12)*24,.035,"square");
  }

  function updateStars(dt){
    movePlayer(dt);spawnClock+=dt;
    if(spawnClock>.46){
      spawnClock=0;
      var danger=Math.random()<.25;
      objects.push({x:18+Math.random()*604,y:-18,r:danger?12:10,speed:125+Math.random()*105,danger:danger,spin:Math.random()*Math.PI});
    }
    for(var i=objects.length-1;i>=0;i--){
      var item=objects[i];item.y+=item.speed*dt;item.spin+=dt*2;
      if(hitCircleRect(item,player)){
        if(item.danger)changeLives(-1);else addScore(1);
        objects.splice(i,1);
      }else if(item.y-item.r>canvas.height)objects.splice(i,1);
    }
  }

  function updateMoon(dt){
    var previousBottom=player.y+player.h;
    movePlayer(dt);player.vy+=780*dt;player.y+=player.vy*dt;
    if(player.y<0){player.y=0;player.vy=Math.abs(player.vy);}
    if(player.vy>0){
      for(var i=0;i<platforms.length;i++){
        var platform=platforms[i];
        if(previousBottom<=platform.y&&player.y+player.h>=platform.y&&player.x+player.w>platform.x&&player.x<platform.x+platform.w){
          player.y=platform.y-player.h;player.vy=-445;addScore(1);
          if(platform.y<320)platform.x=18+Math.random()*(canvas.width-platform.w-36);
          break;
        }
      }
    }
    if(player.y>canvas.height+25){
      changeLives(-1);player.x=305;player.y=295;player.vy=-445;
    }
  }

  function updateRocket(dt){
    movePlayer(dt);spawnClock+=dt;
    if(spawnClock>.42){
      spawnClock=0;
      var energy=Math.random()<.28;
      objects.push({x:28+Math.random()*584,y:-25,r:energy?10:14,speed:155+Math.random()*125,energy:energy,spin:Math.random()*Math.PI});
    }
    for(var i=objects.length-1;i>=0;i--){
      var item=objects[i];item.y+=item.speed*dt;item.spin+=dt*2.8;
      if(hitCircleRect(item,player)){
        if(item.energy)addScore(2);else changeLives(-1);
        objects.splice(i,1);
      }else if(item.y-item.r>canvas.height){
        if(!item.energy)addScore(1);
        objects.splice(i,1);
      }
    }
  }

  function updateBreaker(dt){
    movePlayer(dt);
    ball.x+=ball.vx*dt;ball.y+=ball.vy*dt;
    if(ball.x-ball.r<0){ball.x=ball.r;ball.vx=Math.abs(ball.vx);}
    if(ball.x+ball.r>canvas.width){ball.x=canvas.width-ball.r;ball.vx=-Math.abs(ball.vx);}
    if(ball.y-ball.r<0){ball.y=ball.r;ball.vy=Math.abs(ball.vy);}
    if(ball.vy>0&&hitCircleRect(ball,player)){
      ball.y=player.y-ball.r;ball.vy=-Math.abs(ball.vy)-3;
      ball.vx+=(ball.x-(player.x+player.w/2))*2.3;ball.vx=Math.max(-310,Math.min(310,ball.vx));beep(340,.035,"square");
    }
    for(var i=bricks.length-1;i>=0;i--){
      if(hitCircleRect(ball,bricks[i])){
        ball.vy*=-1;bricks.splice(i,1);addScore(1);break;
      }
    }
    if(ball.y-ball.r>canvas.height){
      changeLives(-1);ball.x=320;ball.y=290;ball.vx=Math.random()<.5?-185:185;ball.vy=-215;
    }
    if(!bricks.length)endGame("SCREEN CLEARED!");
  }

  function update(dt){
    elapsed+=dt;
    var id=games[selectedGame].id;
    if(id==="stars")updateStars(dt);
    else if(id==="moon")updateMoon(dt);
    else if(id==="rocket")updateRocket(dt);
    else updateBreaker(dt);
    timeEl.textContent=String(Math.max(0,20-Math.floor(elapsed)));
    if(running&&(elapsed>=20||lives<=0))endGame();
  }

  function drawStar(x,y,r,color,rotation){
    ctx.fillStyle=color;ctx.beginPath();
    for(var i=0;i<10;i++){
      var angle=rotation-Math.PI/2+i*Math.PI/5;
      var radius=i%2===0?r:r*.45;
      var px=x+Math.cos(angle)*radius,py=y+Math.sin(angle)*radius;
      if(i===0)ctx.moveTo(px,py);else ctx.lineTo(px,py);
    }
    ctx.closePath();ctx.fill();
  }
  function drawGrid(background,grid){
    ctx.fillStyle=background;ctx.fillRect(0,0,canvas.width,canvas.height);
    ctx.globalAlpha=.34;ctx.fillStyle=grid;
    for(var x=0;x<canvas.width;x+=32)ctx.fillRect(x,0,1,canvas.height);
    for(var y=0;y<canvas.height;y+=32)ctx.fillRect(0,y,canvas.width,1);
    ctx.globalAlpha=1;
  }
  function drawStarsBackground(color,speed){
    ctx.fillStyle=color;
    for(var i=0;i<stars.length;i++){
      var star=stars[i],y=(star.y+elapsed*speed*(star.s*.35))%canvas.height;
      ctx.fillRect(star.x,y,star.s,star.s);
    }
  }
  function drawStarGame(colors){
    drawGrid(colors.bg,colors.grid);
    ctx.fillStyle=colors.player;ctx.fillRect(player.x,player.y,player.w,player.h);ctx.fillRect(player.x+25,player.y-11,20,11);
    ctx.fillStyle=colors.star;ctx.fillRect(player.x+31,player.y-17,8,6);
    for(var i=0;i<objects.length;i++){
      var item=objects[i];
      if(item.danger){
        ctx.save();ctx.translate(item.x,item.y);ctx.rotate(item.spin);ctx.fillStyle=colors.danger;ctx.fillRect(-item.r,-item.r,item.r*2,item.r*2);ctx.fillStyle=colors.bg;ctx.fillRect(-2,-item.r,4,item.r*2);ctx.fillRect(-item.r,-2,item.r*2,4);ctx.restore();
      }else drawStar(item.x,item.y,item.r,colors.star,item.spin);
    }
  }
  function drawMoon(colors){
    ctx.fillStyle="#17172f";ctx.fillRect(0,0,canvas.width,canvas.height);drawStarsBackground("#d7f6ff",5);
    ctx.fillStyle="#d7d1c7";ctx.beginPath();ctx.arc(558,65,42,0,Math.PI*2);ctx.fill();
    ctx.fillStyle="#a49ca5";ctx.beginPath();ctx.arc(544,53,8,0,Math.PI*2);ctx.fill();ctx.beginPath();ctx.arc(570,75,11,0,Math.PI*2);ctx.fill();
    for(var i=0;i<platforms.length;i++){
      var platform=platforms[i];ctx.fillStyle=i%2?colors.player:colors.star;ctx.fillRect(platform.x,platform.y,platform.w,platform.h);ctx.fillStyle=colors.grid;ctx.fillRect(platform.x+8,platform.y+3,platform.w-16,3);
    }
    ctx.fillStyle=colors.danger;ctx.fillRect(player.x,player.y+5,player.w,player.h-5);
    ctx.fillStyle="#d7f6ff";ctx.fillRect(player.x+5,player.y,player.w-10,13);
    ctx.fillStyle=colors.bg;ctx.fillRect(player.x+9,player.y+4,player.w-18,6);
    ctx.fillStyle=colors.star;ctx.fillRect(player.x-4,player.y+12,5,12);ctx.fillRect(player.x+player.w-1,player.y+12,5,12);
  }
  function drawRocket(colors){
    ctx.fillStyle="#111226";ctx.fillRect(0,0,canvas.width,canvas.height);drawStarsBackground("#d7f6ff",72);
    ctx.globalAlpha=.28;ctx.strokeStyle=colors.player;ctx.lineWidth=2;
    for(var lane=1;lane<5;lane++){ctx.beginPath();ctx.moveTo(lane*128,0);ctx.lineTo(lane*128,360);ctx.stroke();}
    ctx.globalAlpha=1;
    ctx.save();ctx.translate(player.x+player.w/2,player.y+player.h/2);
    ctx.fillStyle=colors.player;ctx.beginPath();ctx.moveTo(0,-23);ctx.lineTo(20,19);ctx.lineTo(0,11);ctx.lineTo(-20,19);ctx.closePath();ctx.fill();
    ctx.fillStyle=colors.star;ctx.fillRect(-5,-3,10,13);ctx.fillStyle=colors.danger;ctx.beginPath();ctx.moveTo(-9,19);ctx.lineTo(0,34+Math.sin(elapsed*18)*4);ctx.lineTo(9,19);ctx.fill();ctx.restore();
    for(var i=0;i<objects.length;i++){
      var item=objects[i];
      if(item.energy){
        ctx.save();ctx.translate(item.x,item.y);ctx.rotate(item.spin);ctx.strokeStyle=colors.star;ctx.lineWidth=5;ctx.strokeRect(-item.r,-item.r,item.r*2,item.r*2);ctx.restore();
      }else{
        ctx.fillStyle=colors.danger;ctx.beginPath();ctx.arc(item.x,item.y,item.r,0,Math.PI*2);ctx.fill();ctx.fillStyle="#7a2b37";ctx.beginPath();ctx.arc(item.x-4,item.y-3,item.r*.3,0,Math.PI*2);ctx.fill();
      }
    }
  }
  function drawBreaker(colors){
    drawGrid("#171326",colors.grid);
    var brickColors=[colors.danger,"#f65b9a",colors.star,colors.player];
    for(var i=0;i<bricks.length;i++){
      var brick=bricks[i];ctx.fillStyle=brickColors[brick.row%brickColors.length];ctx.fillRect(brick.x,brick.y,brick.w,brick.h);ctx.fillStyle="#ffffff55";ctx.fillRect(brick.x+4,brick.y+4,brick.w-8,3);
    }
    ctx.fillStyle=colors.player;ctx.fillRect(player.x,player.y,player.w,player.h);ctx.fillStyle=colors.star;ctx.fillRect(player.x+12,player.y+3,player.w-24,4);
    ctx.fillStyle="#fffaf0";ctx.beginPath();ctx.arc(ball.x,ball.y,ball.r,0,Math.PI*2);ctx.fill();ctx.strokeStyle=colors.star;ctx.lineWidth=3;ctx.stroke();
  }
  function draw(){
    var colors={bg:css("--game-bg"),grid:css("--game-grid"),player:css("--game-player"),star:css("--game-star"),danger:css("--game-danger")};
    var id=games[selectedGame].id;
    if(id==="stars")drawStarGame(colors);
    else if(id==="moon")drawMoon(colors);
    else if(id==="rocket")drawRocket(colors);
    else drawBreaker(colors);
  }
  function frame(timestamp){
    if(!running)return;
    if(!last)last=timestamp;
    var dt=Math.min(.035,(timestamp-last)/1000);last=timestamp;
    update(dt);draw();
    if(running)raf=window.requestAnimationFrame(frame);
  }
  function endGame(customResult){
    if(!running)return;
    running=false;window.cancelAnimationFrame(raf);gameView.classList.add("is-over");
    result.textContent=customResult||(lives<=0?"GAME OVER — TRY AGAIN":"ARCADE COMPLETE");
    var id=games[selectedGame].id;
    if(id==="stars")finalScore.textContent="You caught "+score+" star"+(score===1?".":"s.");
    else if(id==="moon")finalScore.textContent="You landed "+score+" moon hop"+(score===1?".":"s.");
    else if(id==="rocket")finalScore.textContent="Flight score: "+score+" points.";
    else finalScore.textContent="You smashed "+score+" brick"+(score===1?".":"s.");
    beep(180,.16,"square");
  }
  function hold(button,direction){
    function on(event){event.preventDefault();if(direction<0)moveLeft=true;else moveRight=true;}
    function off(){if(direction<0)moveLeft=false;else moveRight=false;}
    button.addEventListener("pointerdown",on);button.addEventListener("pointerup",off);button.addEventListener("pointercancel",off);button.addEventListener("pointerleave",off);
  }

  usbButton.addEventListener("click",boot);
  root.querySelector(".pcd-play").addEventListener("click",resetGame);
  root.querySelector(".pcd-prev").addEventListener("click",function(){selectGame(selectedGame-1,true);});
  root.querySelector(".pcd-next").addEventListener("click",function(){selectGame(selectedGame+1,true);});
  root.querySelector(".pcd-again").addEventListener("click",resetGame);
  root.querySelector(".pcd-library").addEventListener("click",function(){running=false;window.cancelAnimationFrame(raf);setState("library");selectGame(selectedGame,true);});
  for(var tileIndex=0;tileIndex<tiles.length;tileIndex++){
    (function(index){tiles[index].addEventListener("click",function(){selectGame(index,false);});})(tileIndex);
  }
  soundButton.addEventListener("click",function(){
    audioEnabled=!audioEnabled;soundButton.setAttribute("aria-pressed",audioEnabled?"true":"false");soundButton.textContent=audioEnabled?"SOUND: ON":"SOUND: OFF";beep(440,.07,"square");
  });
  hold(root.querySelector(".pcd-left"),-1);hold(root.querySelector(".pcd-right"),1);
  window.addEventListener("pointerup",function(){moveLeft=false;moveRight=false;});
  root.addEventListener("keydown",function(event){
    var state=screen.getAttribute("data-state");
    if(state==="library"){
      if(event.key==="ArrowLeft"){selectGame(selectedGame-1,true);event.preventDefault();}
      else if(event.key==="ArrowRight"){selectGame(selectedGame+1,true);event.preventDefault();}
      else if(event.key==="ArrowUp"){selectGame(selectedGame-2,true);event.preventDefault();}
      else if(event.key==="ArrowDown"){selectGame(selectedGame+2,true);event.preventDefault();}
      else if(event.key==="Enter"&&event.target.classList.contains("pcd-library-tile")){resetGame();event.preventDefault();}
    }else if(running){
      if(event.key==="ArrowLeft"){moveLeft=true;event.preventDefault();}
      if(event.key==="ArrowRight"){moveRight=true;event.preventDefault();}
    }
  });
  root.addEventListener("keyup",function(event){if(event.key==="ArrowLeft")moveLeft=false;if(event.key==="ArrowRight")moveRight=false;});
  document.addEventListener("visibilitychange",function(){last=0;});
})();
