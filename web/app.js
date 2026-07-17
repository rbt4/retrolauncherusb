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
  for(var i=0;i<anchors.length;i++){
    anchors[i].addEventListener("click",function(event){
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
  var finalScore=root.querySelector(".pcd-final-score");
  var result=root.querySelector(".pcd-result");
  if(!screen||!bootLog||!ctx||!gameView)return;

  var running=false,raf=0,last=0,elapsed=0,spawnClock=0,score=0,lives=3;
  var moveLeft=false,moveRight=false;
  var player={x:285,y:318,w:70,h:18,speed:330};
  var drops=[];
  var bootTimers=[];

  function css(name){return window.getComputedStyle(root).getPropertyValue(name).trim();}
  function setState(state){screen.setAttribute("data-state",state);}
  function addBootLine(text){var line=document.createElement("div");line.textContent=text;bootLog.appendChild(line);}
  function later(fn,delay){bootTimers.push(window.setTimeout(fn,delay));}
  function boot(){
    for(var i=0;i<bootTimers.length;i++)window.clearTimeout(bootTimers[i]);
    bootTimers=[];setState("boot");bootLog.textContent="";addBootLine("CHECKING USB...");
    later(function(){addBootLine("FOUND PLUGCADE 0.3");},300);
    later(function(){addBootLine("KID MODE: READY");},650);
    later(function(){addBootLine("1 GAME FOUND");},950);
    later(function(){setState("library");},reducedMotion?250:1300);
  }
  function resetGame(){
    running=true;last=0;elapsed=0;spawnClock=0;score=0;lives=3;drops=[];player.x=285;moveLeft=false;moveRight=false;
    scoreEl.textContent="0";timeEl.textContent="20";livesEl.textContent="3";
    gameView.classList.remove("is-over");setState("game");
    window.cancelAnimationFrame(raf);raf=window.requestAnimationFrame(frame);
  }
  function spawn(){
    var danger=Math.random()<0.24;
    drops.push({x:18+Math.random()*604,y:-18,r:danger?12:10,speed:120+Math.random()*105,danger:danger,spin:Math.random()*Math.PI});
  }
  function hitCircleRect(drop,box){
    var x=Math.max(box.x,Math.min(drop.x,box.x+box.w));
    var y=Math.max(box.y,Math.min(drop.y,box.y+box.h));
    var dx=drop.x-x,dy=drop.y-y;
    return dx*dx+dy*dy<drop.r*drop.r;
  }
  function update(dt){
    elapsed+=dt;spawnClock+=dt;
    if(moveLeft)player.x-=player.speed*dt;
    if(moveRight)player.x+=player.speed*dt;
    player.x=Math.max(0,Math.min(canvas.width-player.w,player.x));
    if(spawnClock>0.48){spawnClock=0;spawn();}
    for(var i=drops.length-1;i>=0;i--){
      var drop=drops[i];drop.y+=drop.speed*dt;drop.spin+=dt*2;
      if(hitCircleRect(drop,player)){
        if(drop.danger){lives--;livesEl.textContent=String(lives);if(navigator.vibrate)navigator.vibrate(35);}
        else{score++;scoreEl.textContent=String(score);if(navigator.vibrate)navigator.vibrate(12);}
        drops.splice(i,1);
      }else if(drop.y-drop.r>canvas.height){drops.splice(i,1);}
    }
    timeEl.textContent=String(Math.max(0,20-Math.floor(elapsed)));
    if(elapsed>=20||lives<=0)endGame();
  }
  function drawStar(x,y,r,color,rotation){
    ctx.fillStyle=color;ctx.beginPath();
    for(var i=0;i<10;i++){
      var angle=rotation-Math.PI/2+i*Math.PI/5;
      var radius=i%2===0?r:r*0.45;
      var px=x+Math.cos(angle)*radius,py=y+Math.sin(angle)*radius;
      if(i===0)ctx.moveTo(px,py);else ctx.lineTo(px,py);
    }
    ctx.closePath();ctx.fill();
  }
  function draw(){
    var bg=css("--game-bg"),grid=css("--game-grid"),active=css("--game-player"),star=css("--game-star"),danger=css("--game-danger");
    ctx.fillStyle=bg;ctx.fillRect(0,0,canvas.width,canvas.height);
    ctx.globalAlpha=0.34;ctx.fillStyle=grid;
    for(var x=0;x<canvas.width;x+=32)ctx.fillRect(x,0,1,canvas.height);
    for(var y=0;y<canvas.height;y+=32)ctx.fillRect(0,y,canvas.width,1);
    ctx.globalAlpha=1;
    ctx.fillStyle=active;ctx.fillRect(player.x,player.y,player.w,player.h);ctx.fillRect(player.x+25,player.y-11,20,11);
    ctx.fillStyle=star;ctx.fillRect(player.x+31,player.y-17,8,6);
    for(var i=0;i<drops.length;i++){
      var drop=drops[i];
      if(drop.danger){
        ctx.save();ctx.translate(drop.x,drop.y);ctx.rotate(drop.spin);ctx.fillStyle=danger;ctx.fillRect(-drop.r,-drop.r,drop.r*2,drop.r*2);ctx.fillStyle=bg;ctx.fillRect(-2,-drop.r,4,drop.r*2);ctx.fillRect(-drop.r,-2,drop.r*2,4);ctx.restore();
      }else drawStar(drop.x,drop.y,drop.r,star,drop.spin);
    }
  }
  function frame(timestamp){
    if(!running)return;
    if(!last)last=timestamp;
    var dt=Math.min(0.035,(timestamp-last)/1000);last=timestamp;
    update(dt);draw();
    if(running)raf=window.requestAnimationFrame(frame);
  }
  function endGame(){
    running=false;window.cancelAnimationFrame(raf);gameView.classList.add("is-over");
    result.textContent=lives<=0?"GLITCHED — TRY AGAIN":"ARCADE COMPLETE";
    finalScore.textContent="You caught "+score+" star"+(score===1?"":"s")+".";
  }
  function hold(button,direction){
    function on(event){event.preventDefault();if(direction<0)moveLeft=true;else moveRight=true;}
    function off(){if(direction<0)moveLeft=false;else moveRight=false;}
    button.addEventListener("pointerdown",on);button.addEventListener("pointerup",off);button.addEventListener("pointercancel",off);button.addEventListener("pointerleave",off);
  }

  root.querySelector(".pcd-insert").addEventListener("click",boot);
  root.querySelector(".pcd-play").addEventListener("click",resetGame);
  root.querySelector(".pcd-again").addEventListener("click",resetGame);
  root.querySelector(".pcd-library").addEventListener("click",function(){running=false;window.cancelAnimationFrame(raf);setState("library");});
  hold(root.querySelector(".pcd-left"),-1);hold(root.querySelector(".pcd-right"),1);
  window.addEventListener("pointerup",function(){moveLeft=false;moveRight=false;});
  window.addEventListener("keydown",function(event){
    if(!running)return;
    if(event.key==="ArrowLeft"){moveLeft=true;event.preventDefault();}
    if(event.key==="ArrowRight"){moveRight=true;event.preventDefault();}
  });
  window.addEventListener("keyup",function(event){if(event.key==="ArrowLeft")moveLeft=false;if(event.key==="ArrowRight")moveRight=false;});
  document.addEventListener("visibilitychange",function(){last=0;});
})();
