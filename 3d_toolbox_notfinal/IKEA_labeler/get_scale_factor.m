function this_ratio1 = get_scale_factor_hamed(this_type1, this_obj1)
load('ikea_manual_scale_factors', 'type_obj1', 'type1', 'obj1', 'ratio1');
this_type_obj1 = [this_type1 '__' this_obj1];
this_ratio1 = 0;
for i = 1:length(type_obj1)
  if isequal(type_obj1{i}, this_type_obj1)
    this_ratio1 = ratio1(i);
    break
  end
end
if this_ratio1 == 0
  'size not found'
  %this_ratio1 = 1;
  %keyboard
end

  
