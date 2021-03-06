# 
# Type.pm : part of the Mace toolkit for building distributed systems
# 
# Copyright (c) 2011, Charles Killian, James W. Anderson, Adolfo Rodriguez, Dejan Kostic
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
#    * Redistributions of source code must retain the above copyright
#      notice, this list of conditions and the following disclaimer.
#    * Redistributions in binary form must reproduce the above copyright
#      notice, this list of conditions and the following disclaimer in the
#      documentation and/or other materials provided with the distribution.
#    * Neither the names of the contributors, nor their associated universities 
#      or organizations may be used to endorse or promote products derived from
#      this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
# USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# 
# ----END-OF-LEGAL-STUFF----
package Mace::Compiler::Type;

use strict;

use Class::MakeMethods::Template::Hash
    (
     'new' => 'new',
     'string' => "type",
     'boolean' => "isConst",
     'boolean' => "isConst1",
     'boolean' => "isConst2",
     'boolean' => "isRef",
     );

sub toString {
#known accepted flags (passes through all):
#  paramconst
#  paramref
    my $this = shift;
    my %args = @_;
    my $r = "";
    # paramconst has high priority:
    if ($this->isConst1() && !$args{paramconst}) {
        $r .= " const ";
    }
    $r .= $this->type();
    if ($this->isConst2() || $this->isConst() && !$this->isConst1() && !$this->isConst2() || $args{paramconst}) {
#    if ($this->isConst() || $args{paramconst}) {
        $r .= " const ";
    }
    if ($this->isRef() || $args{paramref}) {
        $r .= '&';
    }
    return $r;
} # toString

sub isVoid {
    my $this = shift;
    return ($this->type() eq "void");
}

sub eq {
    my $this = shift;
    my $other = shift;

    return (($this->type() eq $other->type) &&
	    ($this->isConst() == $other->isConst()) &&
	    ($this->isRef() == $other->isRef()));
} # eq

sub name {
    my $this = shift;
    return $this->type();
}

1;
