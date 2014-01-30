 
import SimpleOpenNI.*;
import java.util.Iterator;
//import processing.opengl.*;
import java.util.Map;
import java.util.Iterator;
import java.lang.Math;

PImage recImage;

float z_current;
ArrayList<PVector> rectangleList;
boolean in_region, out_region;
int count_region;
boolean startDrawing = false;
boolean dim_flag = true;
boolean flag_3d = true;
boolean draw_rect = true;
PVector starting;

float z_starting;
float len, wid;

SimpleOpenNI context;

Map<Integer, ArrayList<PVector>> pathList = new HashMap<Integer, ArrayList<PVector>>();


void setup()
{
  rectangleList = new ArrayList<PVector>();
  
  starting = new PVector();
  count_region = 0;
  in_region = false;
  out_region = false;
  
  
   size(640, 480);
   context = new SimpleOpenNI(this); 
   if(context.isInit() == false){
      println("No good");
      return;
   }
   
    
   context.enableDepth();
   context.enableHand();
   context.enableRGB();
   
   context.setMirror(true);
   context.startGesture(SimpleOpenNI.GESTURE_WAVE);
}


void draw()
{
   context.update();
   PImage imag = context.rgbImage();
    image(imag, 0, 0);
   
   /*if(pathList.size() > 0)
   {
      Iterator itr = pathList.entrySet().iterator();
     while(itr.hasNext())
    {
       Map.Entry me = (Map.Entry)itr.next();
       ArrayList<PVector> vecList = (ArrayList<PVector>)me.getValue();
       PVector kin_coord;
       PVector proj_coord = new PVector();
       
       stroke(color(255, 0, 0));
       noFill();
       strokeWeight(1);
       Iterator itrVec = vecList.iterator();
       beginShape();
         while(itrVec.hasNext())
         {
            kin_coord = (PVector) itrVec.next();
            context.convertRealWorldToProjective(kin_coord,proj_coord);
            vertex(proj_coord.x, proj_coord.y);
         }
       endShape();
       
       stroke(color(255, 0, 0));
       strokeWeight(4);
       kin_coord = vecList.get(0);
       context.convertRealWorldToProjective(kin_coord, proj_coord);
       point(proj_coord.x, proj_coord.y);
     
     
    } 
  
     
   }*/
   if(startDrawing)
   {
       ArrayList<PVector> vecList = pathList.get(1);
       PVector current_pos = vecList.get(0);
       PVector current_pos_proj = new PVector();

       context.convertRealWorldToProjective(current_pos, current_pos_proj);
       
       z_current = current_pos_proj.z;

       if(in_region && count_region == 1){
         
         len = current_pos_proj.y - starting.y;
         wid = current_pos_proj.x-starting.x;
       }
       else if(in_region && count_region == 2){       
         starting.x = current_pos_proj.x - wid/2;
         starting.y = current_pos_proj.y - len/2;   
       }
       else if(in_region && count_region == 3){
          draw_rect = false;
       }
       else if( count_region >= 4){

           image(recImage, getLeftMost(rectangleList).x, getLeftMost(rectangleList).y);
       }
       
       if(in_region && count_region == 5){
           starting.x = current_pos_proj.x - wid/2;
           starting.y = current_pos_proj.y - len/2;
       }
       
   
       if(draw_rect){
         drawRect();
       }
       else{
         drawVer();
        
       }


       
   }

}

PVector getLeftMost(ArrayList<PVector> vertices) {
  for (PVector v : vertices){
    for (PVector other : vertices){
      if (!other.equals(v)){
        if (other.y > v.y && other.x > v.x){
          return v;
        }
      }
    }
  }
  return vertices.get(0);
}


//gets part of an image
PImage getPImage(ArrayList<PVector> vertices, PImage im)
{
  int x  = (int) getLeftMost(vertices).x;
  int y = (int) getLeftMost(vertices).y;
  int h = Math.abs((int)vertices.get(0).y - (int)vertices.get(3).y);
  int w = Math.abs((int) vertices.get(1).x - (int)vertices.get(0).x);
    println("taking image");
    return  im.get(x, y, w, h);
  
  
}

void drawVer(){
      PVector side_one = starting;
      PVector side_two = new PVector(side_one.x + wid, side_one.y, z_current);
      PVector side_three = new PVector(side_one.x+wid, side_one.y+len, z_current);
      PVector side_four = new PVector(side_one.x, side_two.y+len, z_current); 
      PVector side_five = starting;
      rectangleList.clear();
      rectangleList.add(0, side_one);
      rectangleList.add(1, side_two);
      rectangleList.add(2, side_three);
      rectangleList.add(3, side_four);
      rectangleList.add(4, side_five);
      Iterator itr = rectangleList.iterator();
      PVector P;
      stroke(255, 0, 0);
      beginShape();
        while(itr.hasNext()){
          P = (PVector)itr.next();
          vertex(P.x, P.y);
        }

      endShape();
     
}


void drawRect(){
       stroke(250, 0, 0);
       noFill();
       rect(starting.x, starting.y, wid, len);
}

//Events:

void onNewHand(SimpleOpenNI curContext,int handId,PVector pos)
{
 println("onNewHand - handId: " + handId + ", pos: " + pos);
 
   ArrayList<PVector> vecList = new ArrayList<PVector>();

   vecList.add(pos);
   
   PVector starting_proj = pos;
   context.convertRealWorldToProjective(starting_proj, starting);
   
   PVector temp = new PVector();
   context.convertRealWorldToProjective(pos, temp);
   z_starting = temp.z;
   //in_region = true;

   
   
   //pathList.put(handId, vecList);
   pathList.put(1, vecList);
 

}

void onTrackedHand(SimpleOpenNI curContext,int handId,PVector pos)
{
  
  if(pos.z - z_starting > 70 && in_region){
    in_region = false; 
  }

  else if( pos.z - z_starting < 70 && !in_region){
     in_region = true;
    count_region++; 
    if((count_region) == 4){
      //context.update();
      recImage = context.rgbImage();
      recImage = getPImage(rectangleList, recImage);
    }
    println("Count = " + count_region);
  }

  //println("onTrackedHand - handId: " + handId + ", pos: " + pos );

  startDrawing = true;

  ArrayList<PVector> vecList = pathList.get(handId);
  if(vecList != null)
  {
     vecList.add(0, pos);
     if(vecList.size() >= 20 && vecList.size() != 1)
     {
        vecList.remove(vecList.size()-1); 
     }
    
  }

 
}

void onLostHand(SimpleOpenNI curContext,int handId)
{
  println("onLostHand - handId: " + handId);
  
  //pathList.remove(handId);
}

// -----------------------------------------------------------------
// gesture events

void onCompletedGesture(SimpleOpenNI curContext,int gestureType, PVector pos)
{
  println("onCompletedGesture - gestureType: " + gestureType + ", pos: " + pos);
  
  int handId = context.startTrackingHand(pos);
  println("hand stracked: " + handId);
}
